import gleam/list
import gleam/float
import gleam/option
import gleam/result
import gleam/otp/actor
import gleam/erlang/process
import radish/resp
import radish/error
import radish/client
import radish/command
import radish/utils.{execute}

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

pub fn set(
  client,
  key: String,
  value: String,
  ttl: option.Option(Int),
  timeout: Int,
) {
  case ttl {
    option.None -> command.set(key, value, [])
    option.Some(ttl) -> command.set(key, value, [command.PX(ttl)])
  }
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

/// only sets a key if it does not already exist
pub fn set_new(
  client,
  key: String,
  value: String,
  ttl: option.Option(Int),
  timeout: Int,
) {
  case ttl {
    option.None -> command.set(key, value, [command.NX])
    option.Some(ttl) -> command.set(key, value, [command.NX, command.PX(ttl)])
  }
  command.set(key, value, [command.NX])
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) | resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// only sets a key if it already exists, returns the old value
pub fn set_existing(
  client,
  key: String,
  value: String,
  ttl: option.Option(Int),
  timeout: Int,
) {
  case ttl {
    option.None -> command.set(key, value, [command.XX, command.GET])
    option.Some(ttl) ->
      command.set(key, value, [command.XX, command.GET, command.PX(ttl)])
  }
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) | resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

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

/// adds 1 to an integer and returns the new value
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

/// adds an arbitrary value to an integer and returns the new value
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

/// adds an arbitrary float value to a number and returns the new value
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

/// subtracts 1 from an integer and returns the new value
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

/// subtracts an arbitrary value from an integer and returns the new value
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

pub fn renamex(client, key: String, new_key: String, timeout: Int) {
  command.renamex(key, new_key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

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
