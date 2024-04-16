import gleam/int
import gleam/list

import radish/utils.{prepare}

pub fn add(key: String, values: List(String)) {
  ["SADD", key]
  |> list.append(values)
  |> prepare
}

pub fn card(key: String) {
  ["SCARD", key]
  |> prepare
}

pub fn is_member(key: String, value: String) {
  ["SISMEMBER", key, value]
  |> prepare
}

pub fn members(key: String) {
  ["SMEMBERS", key]
  |> prepare
}

pub fn scan(key: String, cursor: Int, count: Int) {
  ["SSCAN", key, int.to_string(cursor), "COUNT", int.to_string(count)]
  |> prepare
}

pub fn scan_pattern(key: String, cursor: Int, pattern: String, count: Int) {
  [
    "SSCAN",
    key,
    int.to_string(cursor),
    "MATCH",
    pattern,
    "COUNT",
    int.to_string(count),
  ]
  |> prepare
}
