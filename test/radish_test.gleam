import radish

import gleeunit

pub fn main() {
  gleeunit.main()
}

fn get_test_client(next) {
  let assert Ok(client) = radish.start("localhost", 6379, [radish.Timeout(128)])

  let res = next(client)
  radish.shutdown(client)
  res
}

pub fn roundtrip_test() {
  use client <- get_test_client()
  let assert Ok(_) =
    client
    |> radish.set("key", "value", 1000)

  let assert Ok("value") = client |> radish.get("key", 1000)
}
