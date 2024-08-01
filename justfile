#!/usr/bin/just -f

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

make:
	gleam export erlang-shipment

make-js:
	gleam build --target javascript
	find ./build/dev/javascript -type f -name \*.mjs -exec install -D "{}" "./build/javascript-prod/{}" \;
	install -Dm755 ./scripts/gleam-action.mjs ./build/javascript-prod/entrypoint.mjs

make-locales:
	node ./scripts/locales.js
	gleam format ./src/msgs.gleam

install:
	if [ ! -d ./build/erlang-shipment ]; then just make; fi
	mkdir -p "{{ DESTDIR }}/{{ dir_lib }}"
	rm -rf "{{ DESTDIR }}/{{ dir_lib }}/nemo_gleam"
	cp --preserve=mode -RdT ./build/erlang-shipment "{{ DESTDIR }}/{{ dir_lib }}/nemo_gleam"

	if [ -d ./build/javascript-prod ]; then \
		rm -rf "{{ DESTDIR }}/{{ dir_lib }}/nemo_gleam_js" && \
		cp --preserve=mode -RdT ./build/javascript-prod \
			"{{ DESTDIR }}/{{ dir_lib }}/nemo_gleam_js"; fi

	# Use `install -D` instead of `mkdir -p`
	install -Dvm644 ./actions/new_gleam_project.nemo_action \
		"{{ DESTDIR }}/{{ dir_share }}/nemo/actions/new_gleam_project.nemo_action"
	install -Dvm644 ./actions/gleam_actions.nemo_action \
		"{{ DESTDIR }}/{{ dir_share }}/nemo/actions/gleam_actions.nemo_action"
	install -Dvm755 ./actions/dolphin.desktop \
		"{{ DESTDIR }}/{{ dir_share }}/kio/servicemenus/dolphin_gleam_action.desktop"

	install -Dvm755 ./scripts/gleam-action.sh "{{ DESTDIR }}/{{ dir_bin }}/gleam-action"
	if [ -d ./build/javascript-prod ]; then \
		install -Dvm755 ./scripts/gleam-action-js.sh \
			"{{ DESTDIR }}/{{ dir_bin }}/gleam-action-js"; fi

	install -Dvm644 ./LICENSE "{{ DESTDIR }}/{{ dir_licenses }}/LICENSE"

install-local:
	just DESTDIR="{{ HOMEDIR }}" dir_share=".local/share" dir_bin=".local/bin" dir_lib=".local/lib" \
		dir_licenses=".local/lib/nemo_gleam" install

install-ext-nautilus:
	install -Dvm755 ./scripts/nautilus-caja.sh "{{ dir_ext_nautilus }}"

install-ext-caja:
	install -Dvm755 ./scripts/nautilus-caja.sh "{{ dir_ext_caja }}"

install-ext-pcmanfm:
	install -Dvm755 ./actions/pcmanfm.desktop "{{ dir_ext_pcmanfm }}"

uninstall-local:
	rm -f "{{ dir_ext_nautilus }}"
	rm -f "{{ dir_ext_caja }}"
	rm -f "{{ dir_ext_pcmanfm }}"
	rm -f "{{ HOMEDIR }}/.local/bin/gleam-action"
	rm -rf "{{ HOMEDIR }}/.local/lib/nemo_gleam"
	rm -rf "{{ HOMEDIR }}/.local/lib/nemo_gleam_js"
	rm -f "{{ HOMEDIR }}/.local/share/nemo/actions/new_gleam_project.nemo_action"
	rm -f "{{ HOMEDIR }}/.local/share/nemo/actions/gleam_actions.nemo_action"
	rm -f "{{ HOMEDIR }}/.local/share/kio/servicemenus/dolphin_gleam_action.desktop"

format:
	gleam format

run-actions:
	gleam run -- actions .

git-push:
	git remote | xargs -L1 git push
