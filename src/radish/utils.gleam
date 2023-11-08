import gleam/list
import gleam/result
import gleam/function
import gleam/erlang/process
import radish/error
import radish/client
import radish/encoder.{encode}
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

  use reply <- result.then(reply)
  case reply {
    resp.SimpleError(error) | resp.BulkError(error) ->
      Error(error.ServerError(error))
    value -> Ok(value)
  }
}

pub fn execute_blocking(
  client: process.Subject(client.Message),
  cmd: BitArray,
  timeout: Int,
) {
  let my_subject = process.new_subject()
  process.send(client, client.BlockingCommand(cmd, my_subject, timeout))

  process.new_selector()
  |> process.selecting(my_subject, function.identity)
  |> process.select_forever
  |> fn(reply) {
    case reply {
      Ok(resp.SimpleError(error)) | Ok(resp.BulkError(error)) ->
        Error(error.ServerError(error))
      Ok(value) -> Ok(value)
      Error(error) -> Error(error)
    }
  }
}
