fakemurk.sh: fakemurk.sh.post
	cat header.sh fakemurk.sh.post > $@
	chmod -w $@
	rm -f crossystem.sh.b64 fakemurk.sh.post backdoor.b64 pre-startup.conf.b64 fakemurk-daemon.sh.b64
fakemurk.sh.post: fakemurk.sh.pre crossystem.sh.b64 backdoor.b64 pollen.json.b64 pre-startup.conf.b64 fakemurk-daemon.sh.b64 chromeos_startup.sh.b64
	cpp -P -E -traditional-cpp -o $@ < $<
backdoor:
	# gcc backdoor.c -o backdoor
	:
%.b64: %
	bzip2 -9c $< | base64 -w 100 > $@

clean:
	chmod +w fakemurk.sh
	rm -f fakemurk.sh crossystem.sh.b64 fakemurk.sh.post backdoor.b64 pre-startup.conf.b64 fakemurk-daemon.sh.b64