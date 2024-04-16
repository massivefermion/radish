import gleam/string

import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn hello_radish_test() {
  "radish"
  |> string.starts_with("rad")
  |> should.be_true
}
