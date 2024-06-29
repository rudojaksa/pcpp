PACKAGE	:= pcpp
VERSION	:= 0.8
AUTHOR	:= R.Jaksa 2008,2024 GPLv3
SUBVERSION := a

SHELL	:= /bin/bash
PATH	:= usr/bin:$(PATH)
PKGNAME	:= $(PACKAGE)-$(VERSION)$(SUBVERSION)
SIGN	:= "$(PKGNAME) $(AUTHOR)"
PRJNAME := $(shell getversion -prj)
DATE	:= $(shell date '+%Y-%m-%d')

BIN	:= pcpp uninclude
DEP	:= $(BIN:%=.%.d)
DOC	:= $(BIN:%=doc/%.md)

all: $(BIN) $(DOC)

$(BIN): %: %.pl .%.d Makefile
	echo -e '#!/usr/bin/perl' > $@
	echo -e "# $@ generated from $(PKGNAME)/$< $(DATE)\n" >> $@
	echo -e '$$SIGN = $(SIGN);\n' >> $@
	usr/bin/pcpp $< >> $@
	chmod 755 $@
	@sync # to ensure pcpp is saved before used in the next rule
	@echo

$(DEP): .%.d: %.pl
	pcpp -d $(<:%.pl=%) $< > $@

$(DOC): doc/%.md: % | doc
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
	rm -f $(DEP)

mrproper: clean
	rm -rf doc $(BIN)

-include $(DEP)
-include ~/.github/Makefile.git
