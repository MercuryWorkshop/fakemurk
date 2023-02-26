fakemurk.sh: fakemurk.sh.post
	cat header.sh fakemurk.sh.post > $@
	chmod -w $@
fakemurk.sh.post: fakemurk.sh.pre crossystem.sh.b64
	cpp -P -E -traditional-cpp -o $@ < $<
%.b64: %
	bzip2 -9c $< | base64 -w 100 > $@

clean:
	chmod +w fakemurk.sh
	rm -f fakemurk.sh crossystem.sh.b64 fakemurk.sh.post