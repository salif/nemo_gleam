# GUI extension for Gleam development

[![Package Version](https://img.shields.io/hexpm/v/nemo_gleam)](https://hex.pm/packages/nemo_gleam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/nemo_gleam/)

## Install

Requires [Gleam](https://gleam.run) and [just](https://just.systems/) and runtime only: [Zenity](https://gitlab.gnome.org/GNOME/zenity) and [Erlang](https://www.erlang.org/).

### Build from source

```sh
git clone https://github.com/salif/nemo_gleam.git
cd nemo_gleam

just make

# (Optional) JavaScript target:
# just make-js

# Install to ~/.local/
just install-local
# or
# Install to /usr/
just install
```

### Arch Linux

It's available through the Arch User Repository as package `nemo_gleam`. You can use your prefered helper to install it.

```sh
yay -S nemo_gleam
```

### File managers

The extension will be installed for Nemo and Dolphin.

#### Nautilus

If you use Nautilus file manager, additionally run this command:

```sh
just install-ext-nautilus
```

#### Caja

If you use Caja file manager, additionally run this command:

```sh
just install-ext-caja
```

#### PCManFM

If you use PCMan file manager, additionally run this command:

```sh
just install-ext-pcmanfm
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

Translations are located in the [locales](./locales/) folder.

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
