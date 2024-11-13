import gleam/float
import gleam/int
import gleam/list
import gleam/result

import radish/command/sorted_set as command
import radish/error
import radish/resp
import radish/utils.{execute}

pub type Score {
  Infinity
  Double(Float)
  NegativeInfinity
}

/// see [here](https://redis.io/commands/zadd)!
pub fn add_new(
  client,
  key: String,
  members: List(#(String, Score)),
  timeout: Int,
) {
  command.add_new(key, list.map(members, encode_member))
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zadd)!
pub fn upsert(
  client,
  key: String,
  members: List(#(String, Score)),
  timeout: Int,
) {
  command.upsert(key, list.map(members, encode_member))
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zadd)!
pub fn upsert_only_lower_scores(
  client,
  key: String,
  members: List(#(String, Score)),
  timeout: Int,
) {
  command.upsert_only_lower_scores(key, list.map(members, encode_member))
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zadd)!
pub fn upsert_only_higher_scores(
  client,
  key: String,
  members: List(#(String, Score)),
  timeout: Int,
) {
  command.upsert_only_higher_scores(key, list.map(members, encode_member))
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zadd)!
pub fn update(
  client,
  key: String,
  members: List(#(String, Score)),
  timeout: Int,
) {
  command.update(key, list.map(members, encode_member))
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zadd)!
pub fn update_only_lower_scores(
  client,
  key: String,
  members: List(#(String, Score)),
  timeout: Int,
) {
  command.update_only_lower_scores(key, list.map(members, encode_member))
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zadd)!
pub fn update_only_higher_scores(
  client,
  key: String,
  members: List(#(String, Score)),
  timeout: Int,
) {
  command.update_only_higher_scores(key, list.map(members, encode_member))
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zincrby)!
pub fn incr_by(
  client,
  key: String,
  member: String,
  change_in_score: Score,
  timeout: Int,
) {
  command.incr_by(key, member, encode_score(change_in_score))
  |> execute(client, _, timeout)
  |> result.map(map_score)
  |> result.flatten
}

/// see [here](https://redis.io/commands/zcard)!
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

/// see [here](https://redis.io/commands/zcount)!
pub fn count(client, key: String, min: Score, max: Score, timeout: Int) {
  command.count(key, encode_score(min), encode_score(max))
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zscore)!
pub fn score(client, key: String, member: String, timeout: Int) {
  command.score(key, member)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Infinity] -> Ok(Infinity)
      [resp.Double(score)] -> Ok(Double(score))
      [resp.NegativeInfinity] -> Ok(NegativeInfinity)
      [resp.Null] -> Error(error.NotFound)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zscan)!
pub fn scan(client, key: String, cursor: Int, count: Int, timeout: Int) {
  command.scan(key, cursor, count)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Array([resp.BulkString(new_cursor_str), resp.Array(members)])] ->
        case int.parse(new_cursor_str) {
          Ok(new_cursor) -> {
            use array <- result.then(
              members
              |> list.sized_chunk(2)
              |> list.try_map(fn(item) {
                case item {
                  [resp.BulkString(member), resp.BulkString(score)] ->
                    case decode_score(score) {
                      Ok(score) -> Ok(#(member, score))
                      _ -> Error(error.RESPError)
                    }
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

/// see [here](https://redis.io/commands/zscan)!
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
      [resp.Array([resp.BulkString(new_cursor_str), resp.Array(members)])] ->
        case int.parse(new_cursor_str) {
          Ok(new_cursor) -> {
            use array <- result.then(
              members
              |> list.sized_chunk(2)
              |> list.try_map(fn(item) {
                case item {
                  [resp.BulkString(member), resp.BulkString(score)] ->
                    case decode_score(score) {
                      Ok(score) -> Ok(#(member, score))
                      _ -> Error(error.RESPError)
                    }
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

/// see [here](https://redis.io/commands/zrem)!
pub fn rem(client, key: String, members: List(String), timeout: Int) {
  command.rem(key, members)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Integer(n)] -> Ok(n)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zrandmember)!
pub fn random_members(client, key: String, count: Int, timeout: Int) {
  command.random_members(key, count)
  |> execute(client, _, timeout)
  |> result.map(extract_member_score_pairs)
  |> result.flatten
}

/// see [here](https://redis.io/commands/zrank)!
pub fn rank(client, key: String, member: String, timeout: Int) {
  command.rank(key, member)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Array([resp.Integer(rank), score])] ->
        [score]
        |> map_score
        |> result.map(fn(score) { #(rank, score) })
      [resp.Null] -> Error(error.NotFound)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zrevrank)!
pub fn reverse_rank(client, key: String, member: String, timeout: Int) {
  command.reverse_rank(key, member)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Array([resp.Integer(rank), score])] ->
        [score]
        |> map_score
        |> result.map(fn(score) { #(rank, score) })
      [resp.Null] -> Error(error.NotFound)
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zpopmin)!
pub fn pop_min(client, key: String, count: Int, timeout: Int) {
  command.pop_min(key, count)
  |> execute(client, _, timeout)
  |> result.map(extract_member_score_pairs)
  |> result.flatten
}

/// see [here](https://redis.io/commands/zpopmax)!
pub fn pop_max(client, key: String, count: Int, timeout: Int) {
  command.pop_max(key, count)
  |> execute(client, _, timeout)
  |> result.map(extract_member_score_pairs)
  |> result.flatten
}

/// see [here](https://redis.io/commands/zrange)!
pub fn range(client, key: String, start: Int, stop: Int, timeout: Int) {
  command.range(key, start, stop)
  |> execute(client, _, timeout)
  |> result.map(extract_member_score_pairs)
  |> result.flatten
}

/// see [here](https://redis.io/commands/zrange)!
pub fn head(client, key: String, timeout: Int) {
  command.range(key, 0, 0)
  |> execute(client, _, timeout)
  |> result.map(fn(value) {
    case value {
      [resp.Array([member, ..])] -> {
        use array <- result.then(
          member
          |> fn(item) {
            case item {
              resp.Array([resp.BulkString(member), score]) ->
                case map_score([score]) {
                  Ok(score) -> Ok(#(member, score))
                  _ -> Error(error.RESPError)
                }
              _ -> Error(error.RESPError)
            }
          },
        )
        Ok(array)
      }
      _ -> Error(error.RESPError)
    }
  })
  |> result.flatten
}

/// see [here](https://redis.io/commands/zrevrange)!
pub fn reverse_range(client, key: String, start: Int, stop: Int, timeout: Int) {
  command.reverse_range(key, start, stop)
  |> execute(client, _, timeout)
  |> result.map(extract_member_score_pairs)
  |> result.flatten
}

/// see [here](https://redis.io/commands/zrangebyscore)!
pub fn range_by_score(client, key: String, min: Score, max: Score, timeout: Int) {
  command.range_by_score(key, encode_score(min), encode_score(max))
  |> execute(client, _, timeout)
  |> result.map(extract_member_score_pairs)
  |> result.flatten
}

fn extract_member_score_pairs(value: List(resp.Value)) {
  case value {
    [resp.Array(members)] -> {
      use array <- result.then(
        members
        |> list.try_map(fn(item) {
          case item {
            resp.Array([resp.BulkString(member), score]) ->
              case map_score([score]) {
                Ok(score) -> Ok(#(member, score))
                _ -> Error(error.RESPError)
              }
            _ -> Error(error.RESPError)
          }
        }),
      )
      Ok(array)
    }
    _ -> Error(error.RESPError)
  }
}

fn encode_member(member: #(String, Score)) {
  #(member.0, encode_score(member.1))
}

fn encode_score(score: Score) {
  case score {
    Infinity -> "+inf"
    NegativeInfinity -> "-inf"
    Double(score) -> float.to_string(score)
  }
}

fn map_score(score: List(resp.Value)) {
  case score {
    [resp.Infinity] -> Ok(Infinity)
    [resp.Double(score)] -> Ok(Double(score))
    [resp.NegativeInfinity] -> Ok(NegativeInfinity)
    _ -> Error(error.RESPError)
  }
}

fn decode_score(score: String) {
  case score {
    "+inf" | "inf" -> Ok(Infinity)
    "-inf" -> Ok(NegativeInfinity)
    _ ->
      case int.parse(score) {
        Ok(score) ->
          score
          |> int.to_float
          |> Double
          |> Ok

        Error(Nil) ->
          score
          |> float.parse
          |> result.map(Double)
      }
  }
}
