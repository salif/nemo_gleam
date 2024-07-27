#!/bin/sh
set -eu

BASE=$(dirname $(dirname "$0"))/lib/nemo_gleam_js

node "$BASE"/entrypoint.mjs "$@"
