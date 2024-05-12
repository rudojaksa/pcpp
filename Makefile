PACKAGE	:= pcpp
VERSION	:= 0.4
AUTHOR	:= R.Jaksa 2008,2024 GPLv3
SUBVERSION := b

SHELL	:= /bin/bash
PATH	:= usr/bin:$(PATH)
PKGNAME	:= $(PACKAGE)-$(VERSION)$(SUBVERSION)
SIGN	:= "$(PKGNAME) $(AUTHOR)"
PRJNAME := $(shell getversion -prj)
DATE	:= $(shell date '+%Y-%m-%d')

BIN	:= pcpp uninclude
DOC	:= $(BIN:%=doc/%.md)
BDEP	:= $(shell pcpp -lp $(BIN:%=%.pl))

all: $(BIN) $(DOC)

%: %.pl $(BDEP) Makefile
	echo -e '#!/usr/bin/perl' > $@
	echo -e "# $@ generated from $(PKGNAME)/$< $(DATE)\n" >> $@
	echo -e '$$SIGN = $(SIGN);\n' >> $@
	usr/bin/pcpp $< >> $@
	chmod 755 $@
	@sync # to ensure pcpp is saved before used in the next rule
	@echo

$(DOC): doc/%.md: %.pl Makefile | doc
	./$* -h | man2md > $@
doc:
	mkdir -p doc

# /map install
ifneq ($(wildcard /map),)
install: $(BIN)
	mapinstall /box/$(PRJNAME)/$(PKGNAME) /map/$(PACKAGE) bin $(BIN)

# /usr/local install
else
install: $(BIN)
	install $(BIN) /usr/local/bin
endif

clean:
	rm -rf doc

mrproper: clean
	rm -f pcpp uninclude

-include ~/.github/Makefile.git
