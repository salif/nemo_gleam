#!/usr/bin/just -f

DESTDIR := ""
HOME_DIR := home_directory()
dir_ext_nautilus := HOME_DIR / ".local/share/nautilus/scripts/gleam-actions"
dir_ext_caja := HOME_DIR / ".config/caja/scripts/gleam-actions"
dir_ext_pcmanfm := HOME_DIR / ".local/share/file-manager/actions/gleam_actions.desktop"

default:
    @just --list --unsorted

make:
    gleam export erlang-shipment

make-js:
    gleam build --target javascript
    find ./build/dev/javascript -type f -name \*.mjs -exec install -D {} ./build/javascript-prod/{} \;
    install -Dm755 ./scripts/gleam-action.mjs ./build/javascript-prod/entrypoint.mjs

make-locales:
    node ./scripts/locales.js
    gleam format ./src/msgs.gleam

install:
    ./build/erlang-shipment/entrypoint.sh run self-install system

install-local:
    ./build/erlang-shipment/entrypoint.sh run self-install

install-destdir:
    ./build/erlang-shipment/entrypoint.sh run self-install system destdir {{ DESTDIR }}

install-ext-nautilus:
    install -Dvm755 ./scripts/nautilus-caja.sh {{ dir_ext_nautilus }}

install-ext-caja:
    install -Dvm755 ./scripts/nautilus-caja.sh {{ dir_ext_caja }}

install-ext-pcmanfm:
    install -Dvm755 ./actions/pcmanfm.desktop {{ dir_ext_pcmanfm }}

uninstall-local:
    rm -f {{ dir_ext_nautilus }}
    rm -f {{ dir_ext_caja }}
    rm -f {{ dir_ext_pcmanfm }}
    rm -f "{{ HOME_DIR }}/.local/bin/gleam-action"
    rm -rf "{{ HOME_DIR }}/.local/lib/nemo_gleam"
    rm -rf "{{ HOME_DIR }}/.local/lib/nemo_gleam_js"
    rm -f "{{ HOME_DIR }}/.local/share/nemo/actions/new_gleam_project.nemo_action"
    rm -f "{{ HOME_DIR }}/.local/share/nemo/actions/gleam_actions.nemo_action"
    rm -f "{{ HOME_DIR }}/.local/share/kio/servicemenus/dolphin_gleam_action.desktop"

format:
    gleam format
    just --unstable --fmt -f justfile

run-actions:
    gleam run -- actions .

git-push:
    git remote | xargs -L1 git push
