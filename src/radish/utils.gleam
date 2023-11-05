import gleam/list
import gleam/result
import gleam/erlang/process
import radish/error
import radish/client
import radish/encoder.{encode}
import radish/decoder.{decode}
import radish/resp.{Array, BulkString}

pub fn prepare(parts: List(String)) {
  parts
  |> list.map(BulkString)
  |> Array
  |> encode
}

pub fn execute(
  client: process.Subject(client.Message),
  cmd: BitArray,
  timeout: Int,
) {
  use reply <- result.then(
    process.try_call(client, client.Command(cmd, _, timeout), timeout)
    |> result.replace_error(error.ActorError),
  )

  use reply <- result.then(
    reply
    |> result.map_error(fn(tcp_error) { error.TCPError(tcp_error) }),
  )

  use reply <- result.then(decode(reply))

  case reply {
    value -> Ok(value)
    resp.SimpleError(error) | resp.BulkError(error) ->
      Error(error.ServerError(error))
  }
}
