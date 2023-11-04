import gleam/int
import gleam/list
import gleam/float
import radish/resp.{Array, BulkString}
import radish/encoder.{encode}

pub type SetOption {
  NX
  XX
  GET
  KEEPTTL
  EX(Int)
  PX(Int)
  EXAT(Int)
  PXAT(Int)
}

pub fn hello(protocol: Int) {
  [BulkString("HELLO"), BulkString(int.to_string(protocol))]
  |> Array
  |> encode
}

pub fn get(key: String) {
  [BulkString("GET"), BulkString(key)]
  |> Array
  |> encode
}

pub fn set(key: String, value: String, options: List(SetOption)) {
  list.fold(
    options,
    [BulkString("SET"), BulkString(key), BulkString(value)],
    fn(cmd, option) {
      case option {
        NX -> list.append(cmd, [BulkString("NX")])
        XX -> list.append(cmd, [BulkString("XX")])
        GET -> list.append(cmd, [BulkString("GET")])
        KEEPTTL -> list.append(cmd, [BulkString("KEEPTTL")])

        EX(value) ->
          list.append(
            cmd,
            [
              BulkString("EX"),
              BulkString(
                value
                |> int.to_string,
              ),
            ],
          )

        PX(value) ->
          list.append(
            cmd,
            [
              BulkString("PX"),
              BulkString(
                value
                |> int.to_string,
              ),
            ],
          )

        EXAT(value) ->
          list.append(
            cmd,
            [
              BulkString("EXAT"),
              BulkString(
                value
                |> int.to_string,
              ),
            ],
          )

        PXAT(value) ->
          list.append(
            cmd,
            [
              BulkString("PXAT"),
              BulkString(
                value
                |> int.to_string,
              ),
            ],
          )
      }
    },
  )
  |> Array
  |> encode
}

pub fn keys(pattern: String) {
  [BulkString("KEYS"), BulkString(pattern)]
  |> Array
  |> encode
}

pub fn del(keys: List(String)) {
  [BulkString("DEL")]
  |> list.append(list.map(keys, fn(key) { BulkString(key) }))
  |> Array
  |> encode
}

pub fn exists(keys: List(String)) {
  [BulkString("EXISTS")]
  |> list.append(list.map(keys, fn(key) { BulkString(key) }))
  |> Array
  |> encode
}

pub fn incr(key: String) {
  [BulkString("INCR"), BulkString(key)]
  |> Array
  |> encode
}

pub fn incr_by(key: String, value: Int) {
  [BulkString("INCRBY"), BulkString(key), BulkString(int.to_string(value))]
  |> Array
  |> encode
}

pub fn incr_by_float(key: String, value: Float) {
  [
    BulkString("INCRBYFLOAT"),
    BulkString(key),
    BulkString(float.to_string(value)),
  ]
  |> Array
  |> encode
}

pub fn decr(key: String) {
  [BulkString("DECR"), BulkString(key)]
  |> Array
  |> encode
}

pub fn decr_by(key: String, value: Int) {
  [BulkString("DECRBY"), BulkString(key), BulkString(int.to_string(value))]
  |> Array
  |> encode
}
