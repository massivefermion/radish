import gleam/list
import gleam/result
import gleam/option
import radish/resp
import radish/error
import radish/utils.{execute}
import radish/command/list as command

pub fn lpush(client, key: String, values: List(String), timeout: Int) {
  command.lpush(key, values)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn rpush(client, key: String, values: List(String), timeout: Int) {
  command.rpush(key, values)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn lpushx(client, key: String, values: List(String), timeout: Int) {
  command.lpushx(key, values)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn rpushx(client, key: String, values: List(String), timeout: Int) {
  command.rpushx(key, values)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn llen(client, key: String, timeout: Int) {
  command.llen(key)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn lrange(client, key: String, start: Int, end: Int, timeout: Int) {
  command.lrange(key, start, end)
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

pub fn lpop(client, key: String, timeout: Int) {
  command.lpop(key, option.None)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn rpop(client, key: String, timeout: Int) {
  command.rpop(key, option.None)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.BulkString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn lpop_multiple(client, key: String, count: Int, timeout: Int) {
  command.lpop(key, option.Some(count))
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

pub fn rpop_multiple(client, key: String, count: Int, timeout: Int) {
  command.rpop(key, option.Some(count))
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

pub fn lindex(client, key: String, index: Int, timeout: Int) {
  command.lindex(key, index)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn lrem(client, key: String, count: Int, value: String, timeout: Int) {
  command.lrem(key, count, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn lset(client, key: String, index: Int, value: String, timeout: Int) {
  command.lset(key, index, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.SimpleString(str) -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn linsert_after(
  client,
  key: String,
  pivot: String,
  value: String,
  timeout: Int,
) {
  command.linsert_after(key, pivot, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub fn linsert_before(
  client,
  key: String,
  pivot: String,
  value: String,
  timeout: Int,
) {
  command.linsert_before(key, pivot, value)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      resp.Integer(n) -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}
