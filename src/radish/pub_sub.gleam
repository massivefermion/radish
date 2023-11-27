import gleam/list
import gleam/result
import radish/resp
import radish/error
import radish/utils.{execute, execute_blocking, receive_forever}
import radish/command/pub_sub as command

@deprecated("use radish.Next instead!")
pub type Next {
  Continue
  UnsubscribeFromAll
  UnsubscribeFrom(List(String))
}

/// see [here](https://redis.io/commands/publish)!
@deprecated("use radish.publish instead!")
pub fn publish(client, channel: String, message: String, timeout: Int) {
  command.publish(channel, message)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/subscribe)!
/// Also see [here](https://redis.io/docs/manual/keyspace-notifications)!
@deprecated("use radish.subscribe instead!")
pub fn subscribe(
  client,
  channels: List(String),
  init_handler: fn(String, Int) -> Nil,
  message_handler: fn(String, String) -> Next,
  timeout: Int,
) {
  let _ =
    command.subscribe(channels)
    |> execute_blocking(client, _, timeout)
    |> result.map(fn(value) {
      list.each(
        value,
        fn(item) {
          case item {
            resp.Push([
              resp.BulkString("subscribe"),
              resp.BulkString(channel),
              resp.Integer(n),
            ]) -> Ok(init_handler(channel, n))
            _ -> Error(error.RESPError)
          }
        },
      )
    })

  use value <- receive_forever(client, timeout)
  case value {
    Ok([
      resp.Push([
        resp.BulkString("message"),
        resp.BulkString(channel),
        resp.BulkString(message),
      ]),
    ]) ->
      case message_handler(channel, message) {
        Continue -> True
        UnsubscribeFromAll -> {
          let _ = unsubscribe_from_all(client, timeout)
          False
        }
        UnsubscribeFrom(channels) ->
          case unsubscribe(client, channels, timeout) {
            Ok(result) -> result
            Error(_) -> False
          }
      }

    _ -> False
  }
}

/// see [here](https://redis.io/commands/psubscribe)!
/// Also see [here](https://redis.io/docs/manual/keyspace-notifications)!
@deprecated("use radish.subscribe_to_patterns instead!")
pub fn subscribe_to_patterns(
  client,
  patterns: List(String),
  init_handler: fn(String, Int) -> Nil,
  message_handler: fn(String, String, String) -> Next,
  timeout: Int,
) {
  let _ =
    command.subscribe_to_patterns(patterns)
    |> execute_blocking(client, _, timeout)
    |> result.map(fn(value) {
      list.each(
        value,
        fn(item) {
          case item {
            resp.Push([
              resp.BulkString("psubscribe"),
              resp.BulkString(channel),
              resp.Integer(n),
            ]) -> init_handler(channel, n)
            _ -> Nil
          }
        },
      )
    })

  use value <- receive_forever(client, timeout)
  case value {
    Ok([
      resp.Push([
        resp.BulkString("pmessage"),
        resp.BulkString(pattern),
        resp.BulkString(channel),
        resp.BulkString(message),
      ]),
    ]) ->
      case message_handler(pattern, channel, message) {
        Continue -> True
        UnsubscribeFromAll -> {
          let _ = unsubscribe_from_all_patterns(client, timeout)
          False
        }
        UnsubscribeFrom(patterns) -> {
          case unsubscribe_from_patterns(client, patterns, timeout) {
            Ok(result) -> result
            Error(_) -> False
          }
        }
      }

    _ -> False
  }
}

fn unsubscribe(client, channels: List(String), timeout: Int) {
  command.unsubscribe(channels)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    list.all(
      value,
      fn(item) {
        let assert resp.Push([
          resp.BulkString("unsubscribe"),
          resp.BulkString(_),
          resp.Integer(n),
        ]) = item
        n > 0
      },
    )
  })
}

fn unsubscribe_from_all(client, timeout: Int) {
  command.unsubscribe_from_all()
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    value
    list.all(
      value,
      fn(item) {
        let assert resp.Push([
          resp.BulkString("unsubscribe"),
          resp.BulkString(_),
          resp.Integer(n),
        ]) = item
        n > 0
      },
    )
  })
}

fn unsubscribe_from_patterns(client, patterns: List(String), timeout: Int) {
  command.unsubscribe_from_patterns(patterns)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    list.all(
      value,
      fn(item) {
        let assert resp.Push([
          resp.BulkString("punsubscribe"),
          resp.BulkString(_),
          resp.Integer(n),
        ]) = item
        n > 0
      },
    )
  })
}

fn unsubscribe_from_all_patterns(client, timeout: Int) {
  command.unsubscribe_from_all_patterns()
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    list.all(
      value,
      fn(item) {
        let assert resp.Push([
          resp.BulkString("punsubscribe"),
          resp.BulkString(_),
          resp.Integer(n),
        ]) = item
        n > 0
      },
    )
  })
}
