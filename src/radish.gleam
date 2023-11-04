import gleam/list
import gleam/float
import gleam/option
import gleam/result
import radish/tcp
import radish/error
import radish/resp
import radish/command
import radish/decoder.{decode}

pub fn connect(host: String, port: Int) {
  tcp.connect(host, port, 1024)
  |> result.map(fn(socket) {
    command.hello(3)
    |> execute(socket, _)
    socket
  })
}

pub fn get(socket, key: String) {
  command.get(key)
  |> execute(socket, _)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) | resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn set(socket, key: String, value: String, ttl: option.Option(Int)) {
  case ttl {
    option.None -> command.set(key, value, [])
    option.Some(ttl) -> command.set(key, value, [command.PX(ttl)])
  }
  command.set(key, value, [])
  |> execute(socket, _)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) | resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// only sets a key if it does not already exist
pub fn set_new(socket, key: String, value: String, ttl: option.Option(Int)) {
  case ttl {
    option.None -> command.set(key, value, [command.NX])
    option.Some(ttl) -> command.set(key, value, [command.NX, command.PX(ttl)])
  }
  command.set(key, value, [command.NX])
  |> execute(socket, _)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) | resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// only sets a key if it already exists, returns the old value
pub fn set_existing(socket, key: String, value: String, ttl: option.Option(Int)) {
  case ttl {
    option.None -> command.set(key, value, [command.XX, command.GET])
    option.Some(ttl) ->
      command.set(key, value, [command.XX, command.GET, command.PX(ttl)])
  }
  |> execute(socket, _)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) | resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn del(socket, keys: List(String)) {
  command.del(keys)
  |> execute(socket, _)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// adds 1 to an integer and returns the new value
pub fn incr(socket, key: String) {
  command.incr(key)
  |> execute(socket, _)
  |> result.map(fn(value) {
    case value {
      resp.Integer(new) -> Ok(new)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// adds an arbitrary value to an integer and returns the new value
pub fn incr_by(socket, key: String, value: Int) {
  command.incr_by(key, value)
  |> execute(socket, _)
  |> result.map(fn(value) {
    case value {
      resp.Integer(new) -> Ok(new)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// adds an arbitrary float value to a number and returns the new value
pub fn incr_by_float(socket, key: String, value: Float) {
  command.incr_by_float(key, value)
  |> execute(socket, _)
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
pub fn decr(socket, key: String) {
  command.incr(key)
  |> execute(socket, _)
  |> result.map(fn(value) {
    case value {
      resp.Integer(new) -> Ok(new)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// subtracts an arbitrary value from an integer and returns the new value
pub fn decr_by(socket, key: String, value: Int) {
  command.incr_by(key, value)
  |> execute(socket, _)
  |> result.map(fn(value) {
    case value {
      resp.Integer(new) -> Ok(new)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn exists(socket, keys: List(String)) {
  command.exists(keys)
  |> execute(socket, _)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn keys(socket, pattern: String) {
  command.keys(pattern)
  |> execute(socket, _)
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

fn execute(socket, cmd: BitArray) {
  cmd
  |> tcp.execute(socket, _, 1024)
  |> result.map_error(fn(tcp_error) { error.TCPError(tcp_error) })
  |> result.map(decode)
  |> result.flatten
  |> result.map(fn(value) {
    case value {
      resp.SimpleError(error) | resp.BulkError(error) ->
        Error(error.ServerError(error))
      value -> Ok(value)
    }
  })
  |> result.flatten
}
