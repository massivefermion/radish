import gleam/bit_array
import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/set

import radish/error
import radish/resp

pub fn decode(value: BitArray) -> Result(List(resp.Value), error.Error) {
  decode_multiple(value, [])
  |> result.replace_error(error.RESPError)
}

fn decode_multiple(
  value: BitArray,
  storage: List(resp.Value),
) -> Result(List(resp.Value), error.Error) {
  decode_message(value)
  |> result.map(fn(value) {
    let storage = list.append(storage, [value.0])
    case value {
      #(_, <<>>) -> Ok(storage)
      #(_, rest) -> decode_multiple(rest, storage)
    }
  })
  |> result.replace_error(error.RESPError)
  |> result.flatten
}

fn decode_message(value: BitArray) -> Result(#(resp.Value, BitArray), Nil) {
  case value {
    <<>> -> Error(Nil)

    <<"_\r\n":utf8, rest:bits>> -> Ok(#(resp.Null, rest))
    <<",nan\r\n":utf8, rest:bits>> -> Ok(#(resp.Nan, rest))
    <<",inf\r\n":utf8, rest:bits>> -> Ok(#(resp.Infinity, rest))
    <<"#t\r\n":utf8, rest:bits>> -> Ok(#(resp.Boolean(True), rest))
    <<"#f\r\n":utf8, rest:bits>> -> Ok(#(resp.Boolean(False), rest))
    <<",-inf\r\n":utf8, rest:bits>> -> Ok(#(resp.NegativeInfinity, rest))

    <<":":utf8, rest:bits>> -> {
      use #(value, rest) <- result.then(consume_till_crlf(rest, <<>>))
      use value <- result.then(bit_array.to_string(value))

      value
      |> int.parse
      |> result.map(resp.Integer)
      |> result.map(fn(value) { #(value, rest) })
    }

    <<",":utf8, rest:bits>> -> {
      use #(value, rest) <- result.then(consume_till_crlf(rest, <<>>))
      use value <- result.then(bit_array.to_string(value))

      case int.parse(value) {
        Ok(value) ->
          #(
            value
              |> int.to_float
              |> resp.Double,
            rest,
          )
          |> Ok

        Error(Nil) ->
          value
          |> float.parse
          |> result.map(resp.Double)
          |> result.map(fn(value) { #(value, rest) })
      }
    }

    <<"+":utf8, rest:bits>> -> {
      use #(value, rest) <- result.then(consume_till_crlf(rest, <<>>))
      use value <- result.then(bit_array.to_string(value))

      #(resp.SimpleString(value), rest)
      |> Ok
    }

    <<"-":utf8, rest:bits>> -> {
      use #(value, rest) <- result.then(consume_till_crlf(rest, <<>>))
      use value <- result.then(bit_array.to_string(value))

      #(resp.SimpleError(value), rest)
      |> Ok
    }

    <<"(":utf8, rest:bits>> -> {
      use #(value, rest) <- result.then(consume_till_crlf(rest, <<>>))
      use value <- result.then(bit_array.to_string(value))

      value
      |> int.parse
      |> result.map(resp.BigNumber)
      |> result.map(fn(value) { #(value, rest) })
    }

    <<"$":utf8, rest:bits>> -> {
      use #(length, rest) <- result.then(consume_till_crlf(rest, <<>>))
      use length <- result.then(bit_array.to_string(length))
      use length <- result.then(int.parse(length))

      use #(value, rest) <- result.then(
        consume_by_length(rest, length - 1, <<>>),
      )
      use value <- result.then(bit_array.to_string(value))

      let assert <<"\r\n":utf8, rest:bits>> = rest
      #(resp.BulkString(value), rest)
      |> Ok
    }

    <<"!":utf8, rest:bits>> -> {
      use #(length, rest) <- result.then(consume_till_crlf(rest, <<>>))
      use length <- result.then(bit_array.to_string(length))
      use length <- result.then(int.parse(length))

      use #(value, rest) <- result.then(
        consume_by_length(rest, length - 1, <<>>),
      )
      use value <- result.then(bit_array.to_string(value))

      let assert <<"\r\n":utf8, rest:bits>> = rest
      #(resp.BulkError(value), rest)
      |> Ok
    }

    <<"*":utf8, rest:bits>> -> {
      use #(length, rest) <- result.then(consume_till_crlf(rest, <<>>))
      use length <- result.then(bit_array.to_string(length))
      use length <- result.then(int.parse(length))

      use #(value, rest) <- result.then(decode_array(rest, length, []))
      #(
        value
          |> resp.Array,
        rest,
      )
      |> Ok
    }

    <<">":utf8, rest:bits>> -> {
      use #(length, rest) <- result.then(consume_till_crlf(rest, <<>>))
      use length <- result.then(bit_array.to_string(length))
      use length <- result.then(int.parse(length))

      use #(value, rest) <- result.then(decode_array(rest, length, []))
      #(
        value
          |> resp.Push,
        rest,
      )
      |> Ok
    }

    <<"~":utf8, rest:bits>> -> {
      use #(length, rest) <- result.then(consume_till_crlf(rest, <<>>))
      use length <- result.then(bit_array.to_string(length))
      use length <- result.then(int.parse(length))

      use #(value, rest) <- result.then(decode_array(rest, length, []))
      #(
        value
          |> set.from_list
          |> resp.Set,
        rest,
      )
      |> Ok
    }

    <<"%":utf8, rest:bits>> -> {
      use #(length, rest) <- result.then(consume_till_crlf(rest, <<>>))
      use length <- result.then(bit_array.to_string(length))
      use length <- result.then(int.parse(length))

      use #(value, rest) <- result.then(decode_map(rest, length, []))
      #(
        value
          |> resp.Map,
        rest,
      )
      |> Ok
    }

    _ -> Error(Nil)
  }
}

fn consume_till_crlf(
  data: BitArray,
  storage: BitArray,
) -> Result(#(BitArray, BitArray), Nil) {
  case data {
    <<"\r\n":utf8, rest:bits>> -> Ok(#(storage, rest))
    <<ch:8, rest:bits>> ->
      consume_till_crlf(rest, bit_array.append(storage, <<ch>>))
    _ -> Error(Nil)
  }
}

fn consume_by_length(
  data: BitArray,
  length: Int,
  storage: BitArray,
) -> Result(#(BitArray, BitArray), Nil) {
  case bit_array.byte_size(data) {
    0 -> Error(Nil)
    _ -> {
      let assert <<ch:8, rest:bits>> = data
      case bit_array.byte_size(storage) == length {
        True -> Ok(#(bit_array.append(storage, <<ch>>), rest))
        False ->
          consume_by_length(rest, length, bit_array.append(storage, <<ch>>))
      }
    }
  }
}

fn decode_array(data: BitArray, length: Int, storage: List(resp.Value)) {
  case list.length(storage) == length {
    True -> Ok(#(storage, data))
    False -> {
      use #(item, rest) <- result.then(decode_message(data))
      decode_array(rest, length, list.append(storage, [item]))
    }
  }
}

fn decode_map(
  data: BitArray,
  length: Int,
  storage: List(#(resp.Value, resp.Value)),
) {
  case list.length(storage) == length {
    True -> Ok(#(dict.from_list(storage), data))
    False -> {
      use #(key, rest) <- result.then(decode_message(data))
      use #(value, rest) <- result.then(decode_message(rest))
      decode_map(rest, length, list.append(storage, [#(key, value)]))
    }
  }
}
