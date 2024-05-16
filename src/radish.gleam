//// All timeouts are in milliseconds

import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/otp/actor
import gleam/result

import radish/client
import radish/command
import radish/error
import radish/resp
import radish/utils.{execute, execute_blocking, receive_forever}

pub type Message =
  client.Message

pub type StartOption {
  Timeout(Int)
  Auth(String)
  AuthWithUsername(String, String)
}

pub type KeyType {
  Set
  List
  ZSet
  Hash
  String
  Stream
}

pub type ExpireCondition {
  NX
  XX
  GT
  LT
}

pub fn start(host: String, port: Int, options: List(StartOption)) {
  let #(timeout, options) = case
    list.pop_map(options, fn(item) {
      case item {
        Timeout(timeout) -> Ok(timeout)
        _ -> Error(Nil)
      }
    })
  {
    Ok(result) -> result
    Error(Nil) -> #(1024, options)
  }

  use client <- result.then(client.start(host, port, timeout))

  let options =
    list.map(options, fn(item) {
      case item {
        Auth(password) -> command.Auth(password)
        AuthWithUsername(username, password) ->
          command.AuthWithUsername(username, password)
        Timeout(_) -> command.AuthWithUsername("", "")
      }
    })

  use _ <- result.then(
    execute(client, command.hello(3, options), timeout)
    |> result.map_error(fn(error) {
      case error {
        error.ServerError(error) -> actor.InitFailed(process.Abnormal(error))
        _ -> actor.InitFailed(process.Abnormal("Failed to say hello"))
      }
    }),
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
      [resp.Array(array)] ->
        list.try_map(array, fn(item) {
          case item {
            resp.BulkString(value) -> Ok(value)
            _ -> Error(error.RESPError)
          }
        })
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/scan)!
pub fn scan(client, cursor: Int, count: Int, timeout: Int) {
  command.scan(cursor, count)
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

/// see [here](https://redis.io/commands/scan)!
pub fn scan_pattern(
  client,
  cursor: Int,
  pattern: String,
  count: Int,
  timeout: Int,
) {
  command.scan_pattern(cursor, pattern, count)
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

/// see [here](https://redis.io/commands/scan)!
pub fn scan_with_type(
  client,
  cursor: Int,
  key_type: KeyType,
  count: Int,
  timeout: Int,
) {
  case key_type {
    Set -> command.scan_with_type(cursor, "set", count)
    List -> command.scan_with_type(cursor, "list", count)
    ZSet -> command.scan_with_type(cursor, "zset", count)
    Hash -> command.scan_with_type(cursor, "hash", count)
    String -> command.scan_with_type(cursor, "string", count)
    Stream -> command.scan_with_type(cursor, "stream", count)
  }
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

/// see [here](https://redis.io/commands/scan)!
pub fn scan_pattern_with_type(
  client,
  cursor: Int,
  key_type: KeyType,
  pattern: String,
  count: Int,
  timeout: Int,
) {
  case key_type {
    Set -> command.scan_pattern_with_type(cursor, "set", pattern, count)
    List -> command.scan_pattern_with_type(cursor, "list", pattern, count)
    ZSet -> command.scan_pattern_with_type(cursor, "zset", pattern, count)
    Hash -> command.scan_pattern_with_type(cursor, "hash", pattern, count)
    String -> command.scan_pattern_with_type(cursor, "string", pattern, count)
    Stream -> command.scan_pattern_with_type(cursor, "stream", pattern, count)
  }
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

/// see [here](https://redis.io/commands/exists)!
pub fn exists(client, keys: List(String), timeout: Int) {
  command.exists(keys)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
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
      [resp.SimpleString(str)] | [resp.BulkString(str)] -> Ok(str)
      [resp.Null] -> Error(error.NotFound)
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
      [resp.Array(array)] ->
        list.try_map(array, fn(item) {
          case item {
            resp.BulkString(str) -> Ok(str)
            resp.Null -> Error(error.NotFound)
            _ -> Error(error.RESPError)
          }
        })
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
      [resp.Integer(n)] -> Ok(n)
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
      [resp.SimpleString(str)] | [resp.BulkString(str)] -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/set)!
pub fn set_new(client, key: String, value: String, timeout: Int) {
  command.set(key, value, [command.NX])
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.SimpleString(str)] | [resp.BulkString(str)] -> Ok(str)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/set)!
pub fn set_existing(client, key: String, value: String, timeout: Int) {
  command.set(key, value, [command.XX, command.GET])
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.SimpleString(str)] | [resp.BulkString(str)] -> Ok(str)
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
      [resp.SimpleString(str)] | [resp.BulkString(str)] -> Ok(str)
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
      [resp.Integer(n)] -> Ok(n)
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
      [resp.Integer(new)] -> Ok(new)
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
      [resp.Integer(new)] -> Ok(new)
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
      [resp.BulkString(new)] ->
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
      [resp.Integer(new)] -> Ok(new)
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
      [resp.Integer(new)] -> Ok(new)
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
      [resp.BulkString(str)] -> Ok(str)
      [resp.Null] -> Error(error.NotFound)
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
      [resp.SimpleString(str)] ->
        case str {
          "set" -> Ok(Set)
          "list" -> Ok(List)
          "zset" -> Ok(ZSet)
          "hash" -> Ok(Hash)
          "string" -> Ok(String)
          "stream" -> Ok(Stream)
          _ -> Error(error.RESPError)
        }

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
      [resp.SimpleString(str)] -> Ok(str)
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
      [resp.Integer(n)] -> Ok(n)
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
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/ping)!
/// for use with a custom message, use `ping_message/3`.
pub fn ping(client, timeout: Int) {
  command.ping()
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.SimpleString("PONG")] -> Ok("PONG")
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/ping)!
pub fn ping_message(client, message: String, timeout: Int) {
  command.ping_message(message)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.BulkString(message)] -> Ok(message)
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
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/expire)!
pub fn expire_if(
  client,
  key: String,
  ttl: Int,
  condition: ExpireCondition,
  timeout: Int,
) {
  case condition {
    NX -> command.expire(key, ttl, option.Some("NX"))
    XX -> command.expire(key, ttl, option.Some("XX"))
    GT -> command.expire(key, ttl, option.Some("GT"))
    LT -> command.expire(key, ttl, option.Some("LT"))
  }
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

pub type Next {
  Continue
  UnsubscribeFromAll
  UnsubscribeFrom(List(String))
}

/// see [here](https://redis.io/commands/publish)!
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
      list.each(value, fn(item) {
        case item {
          resp.Push([
            resp.BulkString("subscribe"),
            resp.BulkString(channel),
            resp.Integer(n),
          ]) -> Ok(init_handler(channel, n))
          _ -> Error(error.RESPError)
        }
      })
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
      list.each(value, fn(item) {
        case item {
          resp.Push([
            resp.BulkString("psubscribe"),
            resp.BulkString(channel),
            resp.Integer(n),
          ]) -> init_handler(channel, n)
          _ -> Nil
        }
      })
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
    list.all(value, fn(item) {
      let assert resp.Push([
        resp.BulkString("unsubscribe"),
        resp.BulkString(_),
        resp.Integer(n),
      ]) = item
      n > 0
    })
  })
}

fn unsubscribe_from_all(client, timeout: Int) {
  command.unsubscribe_from_all()
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    list.all(value, fn(item) {
      let assert resp.Push([
        resp.BulkString("unsubscribe"),
        resp.BulkString(_),
        resp.Integer(n),
      ]) = item
      n > 0
    })
  })
}

fn unsubscribe_from_patterns(client, patterns: List(String), timeout: Int) {
  command.unsubscribe_from_patterns(patterns)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    list.all(value, fn(item) {
      let assert resp.Push([
        resp.BulkString("punsubscribe"),
        resp.BulkString(_),
        resp.Integer(n),
      ]) = item
      n > 0
    })
  })
}

fn unsubscribe_from_all_patterns(client, timeout: Int) {
  command.unsubscribe_from_all_patterns()
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    list.all(value, fn(item) {
      let assert resp.Push([
        resp.BulkString("punsubscribe"),
        resp.BulkString(_),
        resp.Integer(n),
      ]) = item
      n > 0
    })
  })
}
