AppName=FileRoller

all:$(AppName).app
	

PREFIX=${HOME}/gtk/inst
BundleVersionCode=4

file-roller.bundle:file-roller.bundle.in Makefile
	sed "s|@PREFIX@|$(PREFIX)|g" file-roller.bundle.in >file-roller.bundle
	

Info.plist:Info.plist.in Makefile
	sed "s|@AppName@|$(AppName)|g;s|@DATE@|$(shell date '+%Y-%m-%d %H:%M:%S%z')|g;s|@BundleVersionCode@|$(BundleVersionCode)|g" Info.plist.in >Info.plist

$(AppName).app: file-roller.bundle launcher.sh Makefile file-roller.icns Info.plist
	@mkdir -p  $(PREFIX)/lib/
	@touch $(PREFIX)/lib/charset.alias
	gtk-mac-bundler file-roller.bundle
	make do_lproj
	make copy-icon-themes
	plutil -convert binary1 "$(AppName).app/Contents/Info.plist"
	@touch "$(AppName).app"

file-roller.icns:Makefile
	cmd=makeicns;\
	for f in 32 48 256 ; \
	do \
		fg="$(PREFIX)/share/icons/hicolor/$${f}x$${f}/apps/file-roller.png"; \
		test -f "$$fg" && cmd="$$cmd -$$f $$fg"; \
	done; \
	$$cmd -out file-roller.icns

do_lproj:
	for d in *.lproj ; \
	do \
		for s in $$d/*.strings; \
		do	\
			mkdir -p  "$(AppName).app/Contents/Resources/$${d}"; \
			plutil -convert binary1 -o "$(AppName).app/Contents/Resources/$${s}" $${s}; \
		done; \
	done

do_strip:
	find "$(AppName).app" -type f |while read f ; \
	do \
		if file "$$f" | grep -q -E "Mach-O.*executable|Mach-O.*shared library" ; then \
			strip  "$$f" 2>/dev/null ; \
		fi; \
	done

copy-icon-themes:
	@mkdir -p "$(AppName).app/Contents/Resources/share/icons"
	for ic in gnome hicolor ; do \
		d="$(PREFIX)/share/icons/$$ic" ; \
		if test -d "$$d"; then \
			cp -r "$$d/" "$(AppName).app/Contents/Resources/share/icons/$$ic/" ; \
			gtk-update-icon-cache -f -i -q "$(AppName).app/Contents/Resources/share/icons/$$ic" ; \
		else \
			continue; \
		fi; \
	done
	@rm -rf "$(AppName).app/Contents/Resources/share/icons/gnome/256x256"
	

cp-plist:Info.plist
	cp -av Info.plist "$(AppName).app/Contents/"
	

dmg:$(AppName).app
	bash -x ~/bin/build_dmg.sh "$(AppName).app"


clean:
	rm -rf "$(AppName).app" file-roller.bundle Info.plist file-roller.icns
