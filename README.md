![radish](https://raw.githubusercontent.com/massivefermion/radish/main/banner.jpg)

[![Package Version](https://img.shields.io/hexpm/v/radish)](https://hex.pm/packages/radish)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/radish/)

# radish

A Gleam client for Valkey, KeyDB, Redis and other tools with compatible APIs

## <img width=32 src="https://raw.githubusercontent.com/massivefermion/radish/main/icon.png"> Quick start

```sh
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

## <img width=32 src="https://raw.githubusercontent.com/massivefermion/radish/main/icon.png"> Installation

```sh
gleam add radish
```

## <img width=32 src="https://raw.githubusercontent.com/massivefermion/radish/main/icon.png"> Usage

```gleam
import radish
import radish/list

pub fn main() {
  let assert Ok(client) =
    radish.start(
      "localhost",
      6379,
      [radish.Timeout(128), radish.Auth("password")],
    )

  radish.set(client, "requests", "64", 128)
  radish.expire(client, "requests", 60, 128)
  radish.decr(client, "requests", 128)

  list.lpush(
    client,
    "names",
    ["Gary", "Andy", "Nicholas", "Danny", "Shaun", "Ed"],
    128,
  )
  list.lpop(client, "names", 128)
}
```
