//// All timeouts are in milliseconds

import gleam/list
import gleam/float
import gleam/option
import gleam/result
import gleam/otp/actor
import gleam/erlang/process
import radish/resp
import radish/error
import radish/client
import radish/utils.{execute}
import radish/command.{type ExpireCondition, GT, LT, NX, XX}

pub fn start(host: String, port: Int, timeout: Int) {
  use client <- result.then(client.start(host, port, timeout))

  use _ <- result.then(
    execute(client, command.hello(3), timeout)
    |> result.replace_error(actor.InitFailed(process.Abnormal(
      "Failed to say hello",
    ))),
  )

  Ok(client)
}

pub fn shutdown(client) {
  process.send(client, client.Shutdown)
}

/// see [here](https://redis.io/commands/keys)!
pub fn keys(client, pattern: String, timeout: Int) {
  command.keys(pattern)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Array(array) ->
        list.try_map(
          array,
          fn(item) {
            case item {
              resp.BulkString(value) -> Ok(value)
              _ -> Error(error.RESPError)
            }
          },
        )
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/exists)!
pub fn exists(client, keys: List(String), timeout: Int) {
  command.exists(keys)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/get)!
pub fn get(client, key: String, timeout: Int) {
  command.get(key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) | resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/mget)!
pub fn mget(client, keys: List(String), timeout: Int) {
  command.mget(keys)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Array(array) ->
        list.try_map(
          array,
          fn(item) {
            case item {
              resp.BulkString(str) -> Ok(str)
              _ -> Error(error.RESPError)
            }
          },
        )
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/append)!
pub fn append(client, key: String, value: String, timeout: Int) {
  command.append(key, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/set)!
pub fn set(client, key: String, value: String, timeout: Int) {
  command.set(key, value, [])
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) | resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/set)!
pub fn set_new(client, key: String, value: String, timeout: Int) {
  command.set(key, value, [command.SNX])
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) | resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/set)!
pub fn set_existing(client, key: String, value: String, timeout: Int) {
  command.set(key, value, [command.SXX, command.GET])
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) | resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/mset)!
pub fn mset(client, kv_list: List(#(String, String)), timeout: Int) {
  command.mset(kv_list)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) | resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/del)!
pub fn del(client, keys: List(String), timeout: Int) {
  command.del(keys)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/incr)!
pub fn incr(client, key: String, timeout: Int) {
  command.incr(key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(new) -> Ok(new)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/incrby)!
pub fn incr_by(client, key: String, value: Int, timeout: Int) {
  command.incr_by(key, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(new) -> Ok(new)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/incrbyfloat)!
pub fn incr_by_float(client, key: String, value: Float, timeout: Int) {
  command.incr_by_float(key, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.BulkString(new) ->
        float.parse(new)
        |> result.replace_error(error.RESPError)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/decr)!
pub fn decr(client, key: String, timeout: Int) {
  command.decr(key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(new) -> Ok(new)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/decrby)!
pub fn decr_by(client, key: String, value: Int, timeout: Int) {
  command.decr_by(key, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(new) -> Ok(new)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/randomkey)!
pub fn random_key(client, timeout: Int) {
  command.random_key()
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.BulkString(str) -> Ok(str)
      resp.Null -> Error(error.EmptyDBError)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/type)!
pub fn key_type(client, key: String, timeout: Int) {
  command.key_type(key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/rename)!
pub fn rename(client, key: String, new_key: String, timeout: Int) {
  command.rename(key, new_key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/renamenx)!
pub fn renamenx(client, key: String, new_key: String, timeout: Int) {
  command.renamenx(key, new_key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/persist)!
pub fn persist(client, key: String, timeout: Int) {
  command.persist(key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/expire)!
pub fn expire(client, key: String, ttl: Int, timeout: Int) {
  command.expire(key, ttl, option.None)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub const nx = NX

pub const xx = XX

pub const gt = GT

pub const lt = LT

/// see [here](https://redis.io/commands/expire)!
pub fn expire_if(
  client,
  key: String,
  ttl: Int,
  condition: ExpireCondition,
  timeout: Int,
) {
  command.expire(key, ttl, option.Some(condition))
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}
