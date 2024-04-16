import gleam/float
import gleam/int
import gleam/list

import radish/utils.{prepare}

pub fn set(key: String, fields: List(#(String, String))) {
  ["HSET", key]
  |> list.append(list.flat_map(fields, fn(kv) { [kv.0, kv.1] }))
  |> prepare
}

pub fn set_new(key: String, field: String, value: String) {
  ["HSETNX", key, field, value]
  |> prepare
}

pub fn keys(key: String) {
  ["HKEYS", key]
  |> prepare
}

pub fn len(key: String) {
  ["HLEN", key]
  |> prepare
}

pub fn get(key: String, field: String) {
  ["HGET", key, field]
  |> prepare
}

pub fn get_all(key: String) {
  ["HGETALL", key]
  |> prepare
}

pub fn mget(key: String, fields: List(String)) {
  ["HMGET", key]
  |> list.append(fields)
  |> prepare
}

pub fn strlen(key: String, field: String) {
  ["HSTRLEN", key, field]
  |> prepare
}

pub fn vals(key: String) {
  ["HVALS", key]
  |> prepare
}

pub fn del(key: String, fields: List(String)) {
  ["HDEL", key]
  |> list.append(fields)
  |> prepare
}

pub fn exists(key: String, field: String) {
  ["HEXISTS", key, field]
  |> prepare
}

pub fn incr_by(key: String, field: String, value: Int) {
  ["HINCRBY", key, field, int.to_string(value)]
  |> prepare
}

pub fn incr_by_float(key: String, field: String, value: Float) {
  ["HINCRBYFLOAT", key, field, float.to_string(value)]
  |> prepare
}

pub fn scan(key: String, cursor: Int, count: Int) {
  ["HSCAN", key, int.to_string(cursor), "COUNT", int.to_string(count)]
  |> prepare
}

pub fn scan_pattern(key: String, cursor: Int, pattern: String, count: Int) {
  [
    "HSCAN",
    key,
    int.to_string(cursor),
    "MATCH",
    pattern,
    "COUNT",
    int.to_string(count),
  ]
  |> prepare
}
