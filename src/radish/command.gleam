import gleam/float
import gleam/int
import gleam/list
import gleam/option

import radish/utils.{prepare}

pub type HelloOption {
  Auth(String)
  AuthWithUsername(String, String)
}

pub type SetOption {
  NX
  XX
  GET
  KEEPTTL
  EX(Int)
  PX(Int)
  EXAT(Int)
  PXAT(Int)
}

pub fn hello(protocol: Int, options: List(HelloOption)) {
  ["HELLO", int.to_string(protocol)]
  |> list.append(
    list.flat_map(options, fn(item) {
      case item {
        Auth(password) -> ["AUTH", "default", password]
        AuthWithUsername(username, password) -> ["AUTH", username, password]
      }
    }),
  )
  |> prepare
}

pub fn custom(command: List(String)) {
  prepare(command)
}

pub fn keys(pattern: String) {
  ["KEYS", pattern]
  |> prepare
}

pub fn scan(cursor: Int, count: Int) {
  ["SCAN", int.to_string(cursor), "COUNT", int.to_string(count)]
  |> prepare
}

pub fn scan_pattern(cursor: Int, pattern: String, count: Int) {
  [
    "SCAN",
    int.to_string(cursor),
    "MATCH",
    pattern,
    "COUNT",
    int.to_string(count),
  ]
  |> prepare
}

pub fn scan_with_type(cursor: Int, key_type: String, count: Int) {
  [
    "SCAN",
    int.to_string(cursor),
    "COUNT",
    int.to_string(count),
    "TYPE",
    key_type,
  ]
  |> prepare
}

pub fn scan_pattern_with_type(
  cursor: Int,
  key_type: String,
  pattern: String,
  count: Int,
) {
  [
    "SCAN",
    int.to_string(cursor),
    "MATCH",
    pattern,
    "COUNT",
    int.to_string(count),
    "TYPE",
    key_type,
  ]
  |> prepare
}

pub fn exists(keys: List(String)) {
  ["EXISTS"]
  |> list.append(keys)
  |> prepare
}

pub fn get(key: String) {
  ["GET", key]
  |> prepare
}

pub fn mget(keys: List(String)) {
  ["MGET"]
  |> list.append(keys)
  |> prepare
}

pub fn append(key: String, value: String) {
  ["APPEND", key, value]
  |> prepare
}

pub fn set(key: String, value: String, options: List(SetOption)) {
  list.fold(options, ["SET", key, value], fn(cmd, option) {
    case option {
      NX -> list.append(cmd, ["NX"])
      XX -> list.append(cmd, ["XX"])
      GET -> list.append(cmd, ["GET"])
      KEEPTTL -> list.append(cmd, ["KEEPTTL"])
      EX(value) -> list.append(cmd, ["EX", int.to_string(value)])
      PX(value) -> list.append(cmd, ["PX", int.to_string(value)])
      EXAT(value) -> list.append(cmd, ["EXAT", int.to_string(value)])
      PXAT(value) -> list.append(cmd, ["PXAT", int.to_string(value)])
    }
  })
  |> prepare
}

pub fn mset(kv_list: List(#(String, String))) {
  kv_list
  |> list.map(fn(kv) { [kv.0, kv.1] })
  |> list.flatten
  |> list.append(["MSET"], _)
  |> prepare
}

pub fn del(keys: List(String)) {
  ["DEL"]
  |> list.append(keys)
  |> prepare
}

pub fn incr(key: String) {
  ["INCR", key]
  |> prepare
}

pub fn incr_by(key: String, value: Int) {
  ["INCRBY", key, int.to_string(value)]
  |> prepare
}

pub fn incr_by_float(key: String, value: Float) {
  ["INCRBYFLOAT", key, float.to_string(value)]
  |> prepare
}

pub fn decr(key: String) {
  ["DECR", key]
  |> prepare
}

pub fn decr_by(key: String, value: Int) {
  ["DECRBY", key, int.to_string(value)]
  |> prepare
}

pub fn random_key() {
  ["RANDOMKEY"]
  |> prepare
}

pub fn key_type(key: String) {
  ["TYPE", key]
  |> prepare
}

pub fn rename(key: String, new_key: String) {
  ["RENAME", key, new_key]
  |> prepare
}

pub fn renamenx(key: String, new_key: String) {
  ["RENAMENX", key, new_key]
  |> prepare
}

pub fn persist(key: String) {
  ["PERSIST", key]
  |> prepare
}

pub fn ping() {
  ["PING"]
  |> prepare
}

pub fn ping_message(message: String) {
  ["PING", message]
  |> prepare
}

pub fn expire(key: String, ttl: Int, expire_if: option.Option(String)) {
  case expire_if {
    option.None -> ["EXPIRE", key, int.to_string(ttl)]
    option.Some(condition) -> ["EXPIRE", key, int.to_string(ttl), condition]
  }
  |> prepare
}

pub fn publish(channel: String, message: String) {
  ["PUBLISH", channel, message]
  |> prepare
}

pub fn subscribe(channels: List(String)) {
  ["SUBSCRIBE"]
  |> list.append(channels)
  |> prepare
}

pub fn subscribe_to_patterns(patterns: List(String)) {
  ["PSUBSCRIBE"]
  |> list.append(patterns)
  |> prepare
}

pub fn unsubscribe(channels: List(String)) {
  ["UNSUBSCRIBE"]
  |> list.append(channels)
  |> prepare
}

pub fn unsubscribe_from_all() {
  ["UNSUBSCRIBE"]
  |> prepare
}

pub fn unsubscribe_from_patterns(patterns: List(String)) {
  ["PUNSUBSCRIBE"]
  |> list.append(patterns)
  |> prepare
}

pub fn unsubscribe_from_all_patterns() {
  ["PUNSUBSCRIBE"]
  |> prepare
}
