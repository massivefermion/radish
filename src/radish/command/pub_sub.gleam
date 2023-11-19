import gleam/list
import radish/utils.{prepare}

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
