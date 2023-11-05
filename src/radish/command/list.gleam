import gleam/int
import gleam/list
import gleam/option
import radish/utils.{prepare}

pub fn lpush(key: String, values: List(String)) {
  ["LPUSH", key]
  |> list.append(list.map(values, fn(value) { value }))
  |> prepare
}

pub fn rpush(key: String, values: List(String)) {
  ["RPUSH", key]
  |> list.append(list.map(values, fn(value) { value }))
  |> prepare
}

pub fn lpushx(key: String, values: List(String)) {
  ["LPUSHX", key]
  |> list.append(list.map(values, fn(value) { value }))
  |> prepare
}

pub fn rpushx(key: String, values: List(String)) {
  ["RPUSHX", key]
  |> list.append(list.map(values, fn(value) { value }))
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

pub fn rpop(key: String, count: option.Option(Int)) {
  case count {
    option.None -> ["RPOP", key]
    option.Some(count) -> ["RPOP", key, int.to_string(count)]
  }
  |> prepare
}
