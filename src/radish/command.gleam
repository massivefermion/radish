import gleam/int
import gleam/list
import gleam/float
import radish/utils.{prepare}

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

pub fn hello(protocol: Int) {
  ["HELLO", int.to_string(protocol)]
  |> prepare
}

pub fn keys(pattern: String) {
  ["KEYS", pattern]
  |> prepare
}

pub fn exists(keys: List(String)) {
  ["EXISTS"]
  |> list.append(list.map(keys, fn(key) { key }))
  |> prepare
}

pub fn get(key: String) {
  ["GET", key]
  |> prepare
}

pub fn mget(keys: List(String)) {
  ["MGET"]
  |> list.append(list.map(keys, fn(key) { key }))
  |> prepare
}

pub fn append(key: String, value: String) {
  ["APPEND", key, value]
  |> prepare
}

pub fn set(key: String, value: String, options: List(SetOption)) {
  list.fold(
    options,
    ["SET", key, value],
    fn(cmd, option) {
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
    },
  )
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
  |> list.append(list.map(keys, fn(key) { key }))
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

pub fn renamex(key: String, new_key: String) {
  ["RENAMEX", key, new_key]
  |> prepare
}

pub fn persist(key: String) {
  ["PERSIST", key]
  |> prepare
}
