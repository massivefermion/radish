import gleam/erlang/process
import gleam/function
import gleam/list
import gleam/result

import radish/client
import radish/encoder.{encode}
import radish/error
import radish/resp.{Array, BulkString}

import lifeguard

pub fn prepare(parts: List(String)) {
  parts
  |> list.map(BulkString)
  |> Array
  |> encode
}

pub fn execute(client: client.Client, cmd: BitArray, timeout: Int) {
  use reply <- result.then(
    lifeguard.call(client, client.Command(cmd, _, timeout), timeout, timeout)
    |> result.replace_error(error.ActorError),
  )

  use reply <- result.then(reply)
  case reply {
    [resp.SimpleError(error)] | [resp.BulkError(error)] ->
      Error(error.ServerError(error))
    value -> Ok(value)
  }
}

pub fn execute_blocking(client: client.Client, cmd: BitArray, timeout: Int) {
  let my_subject = process.new_subject()
  use _ <- result.then(
    lifeguard.send(
      client,
      client.BlockingCommand(cmd, my_subject, timeout),
      timeout,
    )
    |> result.replace_error(error.ActorError),
  )

  process.new_selector()
  |> process.selecting(my_subject, function.identity)
  |> process.select_forever
  |> fn(reply) {
    case reply {
      Ok([resp.SimpleError(error)]) | Ok([resp.BulkError(error)]) ->
        Error(error.ServerError(error))
      Ok(value) -> Ok(value)
      Error(error) -> Error(error)
    }
  }
}

pub fn receive_forever(client: client.Client, timeout: Int, rest) {
  let my_subject = process.new_subject()
  let _ =
    lifeguard.send(client, client.ReceiveForever(my_subject, timeout), timeout)

  process.new_selector()
  |> process.selecting(my_subject, function.identity)
  |> process.select_forever
  |> fn(reply) {
    case reply {
      Ok([resp.SimpleError(error)]) | Ok([resp.BulkError(error)]) -> {
        case rest(Error(error.ServerError(error))) {
          True -> receive_forever(client, timeout, rest)
          False -> Nil
        }
      }
      other -> {
        case rest(other) {
          True -> receive_forever(client, timeout, rest)
          False -> Nil
        }
      }
    }
  }
}
