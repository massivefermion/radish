import gleam/int
import gleam/list

import radish/utils.{prepare}

pub fn add_new(key: String, members: List(#(String, String))) {
  ["ZADD", key, "NX", "CH"]
  |> list.append(list.map(members, fn(member) { member.1 <> member.0 }))
  |> prepare
}

pub fn upsert(key: String, members: List(#(String, String))) {
  ["ZADD", key, "CH"]
  |> list.append(list.map(members, fn(member) { member.1 <> member.0 }))
  |> prepare
}

pub fn upsert_only_lower_scores(key: String, members: List(#(String, String))) {
  ["ZADD", key, "LT", "CH"]
  |> list.append(list.map(members, fn(member) { member.1 <> member.0 }))
  |> prepare
}

pub fn upsert_only_higher_scores(key: String, members: List(#(String, String))) {
  ["ZADD", key, "GT", "CH"]
  |> list.append(list.map(members, fn(member) { member.1 <> member.0 }))
  |> prepare
}

pub fn update(key: String, members: List(#(String, String))) {
  ["ZADD", key, "XX", "CH"]
  |> list.append(list.map(members, fn(member) { member.1 <> member.0 }))
  |> prepare
}

pub fn update_only_lower_scores(key: String, members: List(#(String, String))) {
  ["ZADD", key, "XX", "LT", "CH"]
  |> list.append(list.map(members, fn(member) { member.1 <> member.0 }))
  |> prepare
}

pub fn update_only_higher_scores(key: String, members: List(#(String, String))) {
  ["ZADD", key, "XX", "GT", "CH"]
  |> list.append(list.map(members, fn(member) { member.1 <> member.0 }))
  |> prepare
}

pub fn incr_by(key: String, member: String, change_in_score: String) {
  ["ZINCRBY", key, change_in_score, member]
  |> prepare
}

pub fn card(key: String) {
  ["ZCARD", key]
  |> prepare
}

pub fn count(key: String, min: String, max: String) {
  ["ZCOUNT", key, min, max]
  |> prepare
}

pub fn score(key: String, member: String) {
  ["ZSCORE", key, member]
  |> prepare
}

pub fn scan(key: String, cursor: Int, count: Int) {
  ["ZSCAN", key, int.to_string(cursor), "COUNT", int.to_string(count)]
  |> prepare
}

pub fn scan_pattern(key: String, cursor: Int, pattern: String, count: Int) {
  [
    "ZSCAN",
    key,
    int.to_string(cursor),
    "MATCH",
    pattern,
    "COUNT",
    int.to_string(count),
  ]
  |> prepare
}

pub fn rem(key: String, members: List(String)) {
  ["ZREM", key]
  |> list.append(members)
  |> prepare
}

pub fn random_members(key: String, count: Int) {
  ["ZRANDMEMBER", key, int.to_string(count), "WITHSCORES"]
  |> prepare
}

pub fn rank(key: String, member: String) {
  ["ZRANK", key, member, "WITHSCORE"]
  |> prepare
}

pub fn reverse_rank(key: String, member: String) {
  ["ZREVRANK", key, member, "WITHSCORE"]
  |> prepare
}

pub fn pop_min(key: String, count: Int) {
  ["ZPOPMIN", key, int.to_string(count)]
  |> prepare
}

pub fn pop_max(key: String, count: Int) {
  ["ZPOPMAX", key, int.to_string(count)]
  |> prepare
}

pub fn range(key: String, start: Int, stop: Int) {
  ["ZRANGE", key, int.to_string(start), int.to_string(stop), "WITHSCORES"]
  |> prepare
}

pub fn reverse_range(key: String, start: Int, stop: Int) {
  ["ZREVRANGE", key, int.to_string(start), int.to_string(stop), "WITHSCORES"]
  |> prepare
}

pub fn range_by_score(key: String, min: String, max: String) {
  ["ZRANGEBYSCORE", key, min, max, "WITHSCORES"]
  |> prepare
}
