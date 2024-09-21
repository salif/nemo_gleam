#!/usr/bin/env -S just -f

self_cmd := "gleam-action"
gleam_cmd := "gleam"
# rm_cmd="gio trash"
rm_cmd := "rm -rf"
DESTDIR := ""
HOMEDIR := home_directory()
dir_ext_nautilus := HOMEDIR / ".local/share/nautilus/scripts/gleam-actions"
dir_ext_caja := HOMEDIR / ".config/caja/scripts/gleam-actions"
dir_ext_pcmanfm := HOMEDIR / ".local/share/file-manager/actions/gleam_actions.desktop"
dir_share := "usr/share"
dir_bin := "usr/bin"
dir_lib := "usr/lib"
dir_licenses := "usr/share/licenses/nemo_gleam"

_:
	@just --list --unsorted

[group('build')]
make:
	{{ gleam_cmd }} export erlang-shipment

[group('build')]
make-js:
	{{ gleam_cmd }} build --target javascript
	find ./build/dev/javascript -type f -name \*.mjs -exec install -D "{}" "./build/javascript-prod/{}" \;
	install -Dm755 ./scripts/entrypoint.mjs ./build/javascript-prod/entrypoint.mjs

[group('build')]
make-escript:
	{{ gleam_cmd }} run -m gleescript -- --out=./scripts/
	mv ./scripts/nemo_gleam "./scripts/{{ self_cmd }}-bin"

[private]
make-pkg:
	mkdir -p build pkg
	docker run --rm -v "$PWD/pkg:/src/build/pkg" -v "/src/build" -v "$PWD:/src/:ro" \
	ghcr.io/gleam-lang/gleam:v1.4.1-erlang-alpine sh -c \
		"cd /src && gleam export erlang-shipment && cd ./build/erlang-shipment && tar -czf /src/build/pkg/bin.tar.gz . && chown 1000:1000 /src/build/pkg/bin.tar.gz"

[group('install')]
install:
	if [ ! -d ./build/erlang-shipment ]; then just gleam_cmd="{{ gleam_cmd }}" make; fi
	mkdir -p "{{ DESTDIR }}/{{ dir_lib }}"
	cp --preserve=mode -RdT ./build/erlang-shipment "{{ DESTDIR }}/{{ dir_lib }}/nemo_gleam"

	if [ -d ./build/javascript-prod ]; then \
		cp --preserve=mode -RdT ./build/javascript-prod \
			"{{ DESTDIR }}/{{ dir_lib }}/nemo_gleam_js"; fi

	# Use `install -D` instead of `mkdir -p`
	install -Dvm644 ./actions/gleam_actions.nemo_action \
		"{{ DESTDIR }}/{{ dir_share }}/nemo/actions/gleam_actions.nemo_action"
	install -Dvm755 ./actions/dolphin.desktop \
		"{{ DESTDIR }}/{{ dir_share }}/kio/servicemenus/dolphin_gleam_action.desktop"

	install -Dvm755 ./scripts/bin.sh "{{ DESTDIR }}/{{ dir_bin }}/{{ self_cmd }}"
	if [ -d ./build/javascript-prod ]; then \
		install -Dvm755 ./scripts/bin-js.sh "{{ DESTDIR }}/{{ dir_bin }}/{{ self_cmd }}-js"; fi
	if [ -f "./scripts/{{ self_cmd }}-bin" ]; then \
		install -Dvm755 "./scripts/{{ self_cmd }}-bin" "{{ DESTDIR }}/{{ dir_bin }}/{{ self_cmd }}-bin"; fi

	install -Dvm644 ./LICENSE.txt "{{ DESTDIR }}/{{ dir_licenses }}/LICENSE"

[group('install')]
install-local: && install-ext-nautilus install-ext-caja install-ext-pcmanfm
	-just --yes HOMEDIR="{{ HOMEDIR }}" rm_cmd="{{ rm_cmd }}" uninstall-local
	just self_cmd="{{ self_cmd }}" gleam_cmd="{{ gleam_cmd }}" \
		DESTDIR="{{ HOMEDIR }}" dir_share=".local/share" dir_bin=".local/bin" dir_lib=".local/lib" \
		dir_licenses=".local/lib/nemo_gleam" install
	@printf "\
	{{ HOMEDIR }}/.local/bin/{{ self_cmd }}\n\
	{{ HOMEDIR }}/.local/bin/{{ self_cmd }}-js\n\
	{{ HOMEDIR }}/.local/bin/{{ self_cmd }}-bin\n\
	{{ HOMEDIR }}/.local/lib/nemo_gleam\n\
	{{ HOMEDIR }}/.local/lib/nemo_gleam_js\n\
	{{ HOMEDIR }}/.local/share/nemo/actions/gleam_actions.nemo_action\n\
	{{ HOMEDIR }}/.local/share/kio/servicemenus/dolphin_gleam_action.desktop\n" >> \
		"{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt"

[group('install')]
install-ext-nautilus:
	install -Dvm755 ./scripts/nautilus-caja.sh "{{ dir_ext_nautilus }}"
	@printf "{{ dir_ext_nautilus }}\n" >> "{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt"

[group('install')]
install-ext-caja:
	install -Dvm755 ./scripts/nautilus-caja.sh "{{ dir_ext_caja }}"
	@printf "{{ dir_ext_caja }}\n" >> "{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt"

[group('install')]
install-ext-pcmanfm:
	install -Dvm755 ./actions/pcmanfm.desktop "{{ dir_ext_pcmanfm }}"
	@printf "{{ dir_ext_pcmanfm }}\n" >> "{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt"

[private, confirm]
uninstall-confirm:
	cat "{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt" | xargs {{ rm_cmd }}

[group('install')]
uninstall-local: && uninstall-confirm
	@if [ ! -f "{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt" ]; then \
		printf "Uninstall file not found!\n"; fi
	@printf "Following files will be removed:\n"
	@cat "{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt"

[group('development')]
make-locales:
	node ./scripts/locales.js
	{{ gleam_cmd }} format ./src/msgs.gleam
	# It works only on my machine
	-gleam-patched format ./src/msgs.gleam

[private]
self action='actions':
	{{ gleam_cmd }} run --no-print-progress -- --gleam-cmd "{{ gleam_cmd }}" {{ action }} .
