#!/bin/sh
set -eu
gleam build --target javascript
find ./build/dev/javascript -type f -name \*.mjs -exec install -D {} ./build/javascript-prod/{} \;
install -Dm755 ./scripts/gleam-action.mjs ./build/javascript-prod/entrypoint.mjs
