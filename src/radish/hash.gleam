import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/result

import radish/command/hash as command
import radish/error
import radish/resp
import radish/utils.{execute}

/// see [here](https://redis.io/commands/hset)!
pub fn set(client, key: String, map: dict.Dict(String, String), timeout: Int) {
  command.set(key, dict.to_list(map))
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hsetnx)!
pub fn set_new(client, key: String, field: String, value: String, timeout: Int) {
  command.set_new(key, field, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hlen)!
pub fn len(client, key: String, timeout: Int) {
  command.len(key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hkeys)!
pub fn keys(client, key: String, timeout: Int) {
  command.keys(key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Array(array)] ->
        list.try_map(array, fn(item) {
          case item {
            resp.BulkString(str) -> Ok(str)
            _ -> Error(error.RESPError)
          }
        })
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hget)!
pub fn get(client, key: String, field: String, timeout: Int) {
  command.get(key, field)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.BulkString(str)] -> Ok(str)
      [resp.Null] -> Error(error.NotFound)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hgetall)!
pub fn get_all(client, key: String, timeout: Int) {
  command.get_all(key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Map(map)] -> Ok(map)
      [resp.Array([])] -> Error(error.NotFound)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hmget)!
pub fn mget(client, key: String, fields: List(String), timeout: Int) {
  command.mget(key, fields)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Array(array)] ->
        array
        |> list.filter(fn(item) {
          case item {
            resp.BulkString(_) -> True
            _ -> False
          }
        })
        |> list.try_map(fn(item) {
          case item {
            resp.BulkString(str) -> Ok(str)
            _ -> Error(error.RESPError)
          }
        })
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hstrlen)!
pub fn strlen(client, key: String, field: String, timeout: Int) {
  command.strlen(key, field)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hvals)!
pub fn vals(client, key: String, timeout: Int) {
  command.vals(key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Array(array)] ->
        list.try_map(array, fn(item) {
          case item {
            resp.BulkString(str) -> Ok(str)
            _ -> Error(error.RESPError)
          }
        })
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hdel)!
pub fn del(client, key: String, fields: List(String), timeout: Int) {
  command.del(key, fields)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hexists)!
pub fn exists(client, key: String, field: String, timeout: Int) {
  command.exists(key, field)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hincrby)!
pub fn incr_by(client, key: String, field: String, value: Int, timeout: Int) {
  command.incr_by(key, field, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hincrbyfloat)!
pub fn incr_by_float(
  client,
  key: String,
  field: String,
  value: Float,
  timeout: Int,
) {
  command.incr_by_float(key, field, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.BulkString(str_value)] ->
        case int.parse(str_value) {
          Ok(n) -> Ok(int.to_float(n))
          Error(Nil) ->
            case float.parse(str_value) {
              Ok(f) -> Ok(f)
              Error(Nil) -> Error(error.RESPError)
            }
        }
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/hscan)!
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

/// see [here](https://redis.io/commands/hscan)!
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
