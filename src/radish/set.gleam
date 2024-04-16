//// All timeouts are in milliseconds

import gleam/int
import gleam/list
import gleam/result
import gleam/set

import radish/command/set as command
import radish/error
import radish/resp
import radish/utils.{execute}

/// see [here](https://redis.io/commands/sadd)!
pub fn add(client, key: String, values: List(String), timeout: Int) {
  command.add(key, values)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/scard)!
pub fn card(client, key: String, timeout: Int) {
  command.card(key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/scard)!
pub fn is_member(client, key: String, value: String, timeout: Int) {
  command.is_member(key, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/smembers)!
pub fn members(client, key: String, timeout: Int) {
  command.members(key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Set(set)] -> {
        use list <- result.then(
          set
          |> set.to_list
          |> list.try_map(fn(item) {
            case item {
              resp.BulkString(str) -> Ok(str)
              _ -> Error(error.RESPError)
            }
          }),
        )
        Ok(set.from_list(list))
      }
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/sscan)!
pub fn scan(client, key: String, cursor: Int, count: Int, timeout: Int) {
  command.scan(key, cursor, count)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Array([resp.BulkString(new_cursor_str), resp.Array(keys)])] ->
        case int.parse(new_cursor_str) {
          Ok(new_cursor) -> {
            use array <- result.then(
              list.try_map(keys, fn(item) {
                case item {
                  resp.BulkString(value) -> Ok(value)
                  _ -> Error(error.RESPError)
                }
              }),
            )
            Ok(#(array, new_cursor))
          }
          Error(Nil) -> Error(error.RESPError)
        }
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/sscan)!
pub fn scan_pattern(
  client,
  key: String,
  cursor: Int,
  pattern: String,
  count: Int,
  timeout: Int,
) {
  command.scan_pattern(key, cursor, pattern, count)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Array([resp.BulkString(new_cursor_str), resp.Array(keys)])] ->
        case int.parse(new_cursor_str) {
          Ok(new_cursor) -> {
            use array <- result.then(
              list.try_map(keys, fn(item) {
                case item {
                  resp.BulkString(value) -> Ok(value)
                  _ -> Error(error.RESPError)
                }
              }),
            )
            Ok(#(array, new_cursor))
          }
          Error(Nil) -> Error(error.RESPError)
        }
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}
