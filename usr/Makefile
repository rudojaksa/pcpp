LIBPL := path.pl array.pl color.pl print.pl
LIBPL := $(LIBPL:%=inc/%)

all: bin/pcpp $(LIBPL) inc/printhelp.pl

bin/pcpp: /map/pcpp/bin/pcpp | bin
	cp $< $@

inc/%.pl: /map/libpl/inc/%.pl | inc
	cp $< $@

inc/printhelp.pl: /map/helpman/inc/printhelp.pl | inc
	cp $< $@

bin inc:
	mkdir -p $@

mrproper:
	rm -rf inc bin

