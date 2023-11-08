import gleam/int
import gleam/list
import gleam/option
import radish/utils.{prepare}

pub fn lpush(key: String, values: List(String)) {
  ["LPUSH", key]
  |> list.append(values)
  |> prepare
}

pub fn rpush(key: String, values: List(String)) {
  ["RPUSH", key]
  |> list.append(values)
  |> prepare
}

pub fn lpushx(key: String, values: List(String)) {
  ["LPUSHX", key]
  |> list.append(values)
  |> prepare
}

pub fn rpushx(key: String, values: List(String)) {
  ["RPUSHX", key]
  |> list.append(values)
  |> prepare
}

pub fn llen(key: String) {
  ["LLEN", key]
  |> prepare
}

pub fn lrange(key: String, start: Int, end: Int) {
  ["LRANGE", key, int.to_string(start), int.to_string(end)]
  |> prepare
}

pub fn lpop(key: String, count: option.Option(Int)) {
  case count {
    option.None -> ["LPOP", key]
    option.Some(count) -> ["LPOP", key, int.to_string(count)]
  }
  |> prepare
}

pub fn blpop(keys: List(String), timeout: Int) {
  ["BLPOP"]
  |> list.append(keys)
  |> list.append([int.to_string(timeout)])
  |> prepare
}

pub fn rpop(key: String, count: option.Option(Int)) {
  case count {
    option.None -> ["RPOP", key]
    option.Some(count) -> ["RPOP", key, int.to_string(count)]
  }
  |> prepare
}

pub fn brpop(keys: List(String), timeout: Int) {
  ["BRPOP"]
  |> list.append(keys)
  |> list.append([int.to_string(timeout)])
  |> prepare
}

pub fn lindex(key: String, index: Int) {
  ["LINDEX", key, int.to_string(index)]
  |> prepare
}

pub fn lrem(key: String, count: Int, value: String) {
  ["LREM", key, int.to_string(count), value]
  |> prepare
}

pub fn lset(key: String, index: Int, value: String) {
  ["LSET", key, int.to_string(index), value]
  |> prepare
}

pub fn linsert_after(key: String, pivot: String, value: String) {
  ["LINSERT", key, "AFTER", pivot, value]
  |> prepare
}

pub fn linsert_before(key: String, pivot: String, value: String) {
  ["LINSERT", key, "BEFORE", pivot, value]
  |> prepare
}
