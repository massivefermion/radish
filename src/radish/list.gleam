//// All timeouts are in milliseconds

import gleam/list
import gleam/option
import gleam/result

import radish/command/list as command
import radish/error
import radish/resp
import radish/utils.{execute, execute_blocking}

/// see [here](https://redis.io/commands/lpush)!
pub fn lpush(client, key: String, values: List(String), timeout: Int) {
  command.lpush(key, values)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/rpush)!
pub fn rpush(client, key: String, values: List(String), timeout: Int) {
  command.rpush(key, values)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/lpushx)!
pub fn lpushx(client, key: String, values: List(String), timeout: Int) {
  command.lpushx(key, values)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/rpushx)!
pub fn rpushx(client, key: String, values: List(String), timeout: Int) {
  command.rpushx(key, values)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/llen)!
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

/// see [here](https://redis.io/commands/lrange)!
pub fn range(client, key: String, start: Int, end: Int, timeout: Int) {
  command.range(key, start, end)
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

/// see [here](https://redis.io/commands/lpop)!
pub fn lpop(client, key: String, timeout: Int) {
  command.lpop(key, option.None)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.BulkString(str)] -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/blpop)!
pub fn blpop(client, keys: List(String), timeout: Int) {
  command.blpop(keys, timeout)
  |> execute_blocking(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Array(array)] ->
        list.sized_chunk(array, 2)
        |> list.try_map(fn(kv) {
          case kv {
            [resp.BulkString(key), resp.BulkString(value)] -> Ok(#(key, value))
            _ -> Error(error.RESPError)
          }
        })
      [resp.Null] -> Error(error.NotFound)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/rpop)!
pub fn rpop(client, key: String, timeout: Int) {
  command.rpop(key, option.None)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.BulkString(str)] -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/brpop)!
pub fn brpop(client, keys: List(String), timeout: Int) {
  command.brpop(keys, timeout)
  |> execute_blocking(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Array(array)] ->
        list.sized_chunk(array, 2)
        |> list.try_map(fn(kv) {
          case kv {
            [resp.BulkString(key), resp.BulkString(value)] -> Ok(#(key, value))
            _ -> Error(error.RESPError)
          }
        })
      [resp.Null] -> Error(error.NotFound)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/lpop)!
pub fn lpop_multiple(client, key: String, count: Int, timeout: Int) {
  command.lpop(key, option.Some(count))
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

/// see [here](https://redis.io/commands/rpop)!
pub fn rpop_multiple(client, key: String, count: Int, timeout: Int) {
  command.rpop(key, option.Some(count))
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

/// see [here](https://redis.io/commands/lindex)!
pub fn index(client, key: String, index: Int, timeout: Int) {
  command.index(key, index)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/lrem)!
pub fn rem(client, key: String, count: Int, value: String, timeout: Int) {
  command.rem(key, count, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/lset)!
pub fn set(client, key: String, index: Int, value: String, timeout: Int) {
  command.set(key, index, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.SimpleString(str)] -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/linsert)!
pub fn insert_after(
  client,
  key: String,
  pivot: String,
  value: String,
  timeout: Int,
) {
  command.insert_after(key, pivot, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/linsert)!
pub fn insert_before(
  client,
  key: String,
  pivot: String,
  value: String,
  timeout: Int,
) {
  command.insert_before(key, pivot, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}
