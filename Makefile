fakemurk.sh: fakemurk.sh.post
	cat header.sh fakemurk.sh.post > $@
	chmod -w $@
fakemurk.sh.post: fakemurk.sh.pre lib/ssd_util.sh.b64 crossystem.sh.b64 pollen.json.b64 pre-startup.conf.b64 cr50-update.conf.b64 fakemurk-daemon.sh.b64 chromeos_startup.sh.b64 mush.sh.b64 keymap.map.b64 logkeys.elf.b64 image_patcher.sh.b64
	cpp -P -E -traditional-cpp -o $@ < $<

image_patcher.sh: image_patcher.sh.post 
	cat header.sh image_patcher.sh.post > $@
	chmod -w $@
image_patcher.sh.post: image_patcher.sh.pre crossystem_boot_populator.sh crossystem_boot_populator.sh.b64
	cpp -P -E -traditional-cpp -o $@ < $<
crossystem_boot_populator.sh: crossystem_boot_populator.sh.post 
	cat header.sh crossystem_boot_populator.sh.post > $@
	chmod -w $@
crossystem_boot_populator.sh.post: crossystem_boot_populator.sh.pre
	cpp -P -E -traditional-cpp -o $@ < $<
%.b64: %
	bzip2 -9c $< | base64 -w 100 > $@

clean:
	chmod +w *.sh
	rm -f fakemurk.sh image_patcher.sh crossystem_boot_populator.sh *.post *.b64
