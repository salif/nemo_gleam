# GUI extension for Gleam development

[![Package Version](https://img.shields.io/hexpm/v/nemo_gleam)](https://hex.pm/packages/nemo_gleam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/nemo_gleam/)

## Install

Requires [Zenity](https://gitlab.gnome.org/GNOME/zenity) and [Erlang](https://www.erlang.org/).

### Build from source

```sh
git clone https://github.com/salif/nemo_gleam.git
cd nemo_gleam

gleam export erlang-shipment

# Install to ~/.local/
./build/erlang-shipment/entrypoint.sh run self-install
# or
# Install to /usr/
./build/erlang-shipment/entrypoint.sh run self-install system
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
install -Dvm755 ./scripts/nautilus-caja.sh "$HOME"/.local/share/nautilus/scripts/gleam-actions
```

#### Caja

If you use Caja file manager, additionally run this command:

```sh
install -Dvm755 ./scripts/nautilus-caja.sh "$HOME"/.config/caja/scripts/gleam-actions
```

#### PCManFM

If you use PCMan file manager, additionally run this command:

```sh
install -Dvm755 ./actions/pcmanfm.desktop "$HOME"/.local/share/file-manager/actions/gleam_actions.desktop
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
