#!/bin/sh
set -eu
BASE=$(dirname $(dirname "$0"))/lib/nemo_gleam
erl -pa "$BASE"/*/ebin -eval "nemo_gleam@@main:run(nemo_gleam)" -noshell -extra "$@"
