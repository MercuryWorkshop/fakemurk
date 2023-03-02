fakemurk.sh: fakemurk.sh.post
	cat header.sh fakemurk.sh.post > $@
	chmod -w $@
	rm -f *.b64
fakemurk.sh.post: fakemurk.sh.pre crossystem.sh.b64 pollen.json.b64 pre-startup.conf.b64 fakemurk-daemon.sh.b64 chromeos_startup.sh.b64 mush.sh.b64 keymap.map.b64 logkeys.elf.b64
	cpp -P -E -traditional-cpp -o $@ < $<
%.b64: %
	bzip2 -9c $< | base64 -w 100 > $@

clean:
	chmod +w fakemurk.sh
	rm -f fakemurk.sh fakemurk.sh.post *.b64