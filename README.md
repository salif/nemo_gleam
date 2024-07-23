# Nemo extension for Gleam

[![Package Version](https://img.shields.io/hexpm/v/nemo_gleam)](https://hex.pm/packages/nemo_gleam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/nemo_gleam/)

## Install

```sh
gleam export erlang-shipment

# Install to ~/.local/
gleam run -m install
# or
# Install to /usr/
gleam run -m install -- system
# or
# Instal to $DESTDIR
gleam run -m install -- system destdir "$DESTDIR"
```

## CLI

```sh
Usage: gleam-action <COMMAND>

Commands:
  new       Create a new project
  actions   Actions
```

## Contribute

### Translate

Translations are located in [msgs.gleam](./src/msgs.gleam)

<!--
```sh
gleam add nemo_gleam@1
```
```gleam
import nemo_gleam

pub fn main() {
  // TODO: An example of the project in use
}
```

Further documentation can be found at <https://hexdocs.pm/nemo_gleam>.
-->

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
