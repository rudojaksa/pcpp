PACKAGE	:= pcpp
VERSION	:= 0.9
AUTHOR	:= R.Jaksa 2008,2024 GPLv3
SUBVERSION := a

SHELL	:= /bin/bash
PATH	:= usr/bin:$(PATH)
PKGNAME	:= $(PACKAGE)-$(VERSION)$(SUBVERSION)
PROJECT := $(shell getversion -prj)
DATE	:= $(shell date '+%Y-%m-%d')

BIN	:= pcpp uninclude
DEP	:= $(BIN:%=.%.d)
DOC	:= $(BIN:%=%.md)

all: $(BIN) $(DOC)

$(BIN): %: %.pl .%.d .version.pl .%.built.pl Makefile
	@echo -e '#!/usr/bin/perl' > $@
	@echo -e "# $@ generated from $(PKGNAME)/$< $(DATE)" >> $@
	usr/bin/pcpp $< >> $@
	@chmod 755 $@
	@sync # to ensure pcpp is saved before used in the next rule
	@echo

$(DEP): .%.d: %.pl
	pcpp -d $(<:%.pl=%) $< > $@

$(DOC): %.md: %
	./$* -h | man2md > $@

.version.pl: Makefile
	@echo 'our $$PACKAGE = "$(PACKAGE)";' > $@
	@echo 'our $$VERSION = "$(VERSION)";' >> $@
	@echo 'our $$AUTHOR = "$(AUTHOR)";' >> $@
	@echo 'our $$SUBVERSION = "$(SUBVERSION)";' >> $@
	@echo "make $@"

.PRECIOUS: .%.built.pl
.%.built.pl: %.pl .version.pl Makefile
	@echo 'our $$BUILT = "$(DATE)";' > $@
	@echo "make $@"

# /map install, requires /map directory and getversion and mapinstall tools
ifneq ($(wildcard /map),)
install: $(BIN) $(DOC) README.md
	mapinstall -v /box/$(PROJECT)/$(PKGNAME) /map/$(PACKAGE) bin $(BIN)
	mapinstall -v /box/$(PROJECT)/$(PKGNAME) /map/$(PACKAGE) doc $(DOC) README.md

# /usr/local install
else
install: $(BIN)
	install $(BIN) /usr/local/bin
endif

# copy current pcpp to local usr/bin
copy:
	cp pcpp usr/bin

clean:
	rm -f .version.pl
	rm -f .*.built.pl
	rm -f $(DEP)

mrproper: clean
	rm -rf $(DOC) $(BIN)

-include $(DEP)
-include ~/.github/Makefile.git
