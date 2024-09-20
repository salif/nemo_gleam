#!/usr/bin/env -S just -f

gleam_cmd := "gleam"
# rm_cmd="gio trash"
rm_cmd := "rm -rf"
DESTDIR := ""
HOMEDIR := "$HOME"
dir_ext_nautilus := HOMEDIR / ".local/share/nautilus/scripts/gleam-actions"
dir_ext_caja := HOMEDIR / ".config/caja/scripts/gleam-actions"
dir_ext_pcmanfm := HOMEDIR / ".local/share/file-manager/actions/gleam_actions.desktop"
dir_share := "usr/share"
dir_bin := "usr/bin"
dir_lib := "usr/lib"
dir_licenses := "usr/share/licenses/nemo_gleam"

_:
	@just --list --unsorted

make:
	{{ gleam_cmd }} export erlang-shipment

make-js:
	{{ gleam_cmd }} build --target javascript
	find ./build/dev/javascript -type f -name \*.mjs -exec install -D "{}" "./build/javascript-prod/{}" \;
	install -Dm755 ./scripts/entrypoint.mjs ./build/javascript-prod/entrypoint.mjs

make-locales:
	node ./scripts/locales.js
	{{ gleam_cmd }} format ./src/msgs.gleam

[private]
make-pkg:
	mkdir -p build pkg
	docker run --rm -v "$PWD/pkg:/src/build/pkg" -v "/src/build" -v "$PWD:/src/:ro" ghcr.io/gleam-lang/gleam:v1.4.1-erlang-alpine sh -c \
		"cd /src && gleam export erlang-shipment && cd ./build/erlang-shipment && tar -czf /src/build/pkg/bin.tar.gz . && chown 1000:1000 /src/build/pkg/bin.tar.gz"

install:
	if [ ! -d ./build/erlang-shipment ]; then just gleam_cmd="{{ gleam_cmd }}" make; fi
	mkdir -p "{{ DESTDIR }}/{{ dir_lib }}"
	{{ rm_cmd }} "{{ DESTDIR }}/{{ dir_lib }}/nemo_gleam"
	cp --preserve=mode -RdT ./build/erlang-shipment "{{ DESTDIR }}/{{ dir_lib }}/nemo_gleam"

	if [ -d ./build/javascript-prod ]; then \
		{{ rm_cmd }} "{{ DESTDIR }}/{{ dir_lib }}/nemo_gleam_js" && \
		cp --preserve=mode -RdT ./build/javascript-prod \
			"{{ DESTDIR }}/{{ dir_lib }}/nemo_gleam_js"; fi

	# Use `install -D` instead of `mkdir -p`
	install -Dvm644 ./actions/gleam_actions.nemo_action \
		"{{ DESTDIR }}/{{ dir_share }}/nemo/actions/gleam_actions.nemo_action"
	install -Dvm755 ./actions/dolphin.desktop \
		"{{ DESTDIR }}/{{ dir_share }}/kio/servicemenus/dolphin_gleam_action.desktop"

	install -Dvm755 ./scripts/gleam-action.sh "{{ DESTDIR }}/{{ dir_bin }}/gleam-action"
	if [ -d ./build/javascript-prod ]; then \
		install -Dvm755 ./scripts/gleam-action-js.sh \
			"{{ DESTDIR }}/{{ dir_bin }}/gleam-action-js"; fi

	install -Dvm644 ./LICENSE "{{ DESTDIR }}/{{ dir_licenses }}/LICENSE"

install-local: && install-ext-nautilus install-ext-caja install-ext-pcmanfm
	just gleam_cmd="{{ gleam_cmd }}" rm_cmd="{{ rm_cmd }}" DESTDIR="{{ HOMEDIR }}" dir_share=".local/share" dir_bin=".local/bin" dir_lib=".local/lib" \
		dir_licenses=".local/lib/nemo_gleam" install
	@printf "\
	{{ HOMEDIR }}/.local/bin/gleam-action\n\
	{{ HOMEDIR }}/.local/bin/gleam-action-js\n\
	{{ HOMEDIR }}/.local/lib/nemo_gleam\n\
	{{ HOMEDIR }}/.local/lib/nemo_gleam_js\n\
	{{ HOMEDIR }}/.local/share/nemo/actions/gleam_actions.nemo_action\n\
	{{ HOMEDIR }}/.local/share/kio/servicemenus/dolphin_gleam_action.desktop\n" >> "{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt"

install-ext-nautilus:
	install -Dvm755 ./scripts/nautilus-caja.sh "{{ dir_ext_nautilus }}"
	@printf "{{ dir_ext_nautilus }}\n" >> "{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt"

install-ext-caja:
	install -Dvm755 ./scripts/nautilus-caja.sh "{{ dir_ext_caja }}"
	@printf "{{ dir_ext_caja }}\n" >> "{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt"

install-ext-pcmanfm:
	install -Dvm755 ./actions/pcmanfm.desktop "{{ dir_ext_pcmanfm }}"
	@printf "{{ dir_ext_pcmanfm }}\n" >> "{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt"

[private]
[confirm]
uninstall-confirm:
	cat "{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt" | xargs {{ rm_cmd }}

uninstall-local: && uninstall-confirm
	@printf "Following files will be removed:\n"
	@cat "{{ HOMEDIR }}/.local/lib/nemo_gleam/uninstall.txt"


[private]
run-actions:
	{{ gleam_cmd }} run -- --gleam-cmd "{{ gleam_cmd }}" actions .
