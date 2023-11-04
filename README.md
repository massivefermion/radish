![radish](https://raw.githubusercontent.com/massivefermion/radish/main/banner.jpg)

[![Package Version](https://img.shields.io/hexpm/v/radish)](https://hex.pm/packages/radish)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/radish/)

# radish

bson encoder and decoder for gleam

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
import gleam/option
import radish

pub fn main() {
    let assert Ok(client) = radish.connect("localhost", 6379)

    radish.set(client, "requests", "64", option.Some(60_000))
    radish.decr(client, "requests")
}
```