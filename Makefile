all: c64 apple2 atari

ifeq ($(shell echo),)
  NULLDEV = /dev/null
else
  NULLDEV = nul:
endif

ZIPCOMMENT := $(shell git rev-parse --short HEAD 2>$(NULLDEV))
ifeq ($(words $(ZIPCOMMENT)),1)
  ZIPCOMMENT := https://github.com/cc65/ip65/commit/$(ZIPCOMMENT)
else
  ZIPCOMMENT := N/A
endif

%.zip:
	zip $@ $^
	echo $(ZIPCOMMENT) | zip -z $@

c64: ip65-c64.zip

apple2: ip65-apple2.zip

atari: ip65-atari.zip

ip65-c64.zip:    ip65.h ip65.lib ip65_tcp.lib ip65_c64.lib                    ip65.d64

ip65-apple2.zip: ip65.h ip65.lib ip65_tcp.lib ip65_apple2.lib                 ip65.dsk

ip65-atari.zip:  ip65.h ip65.lib ip65_tcp.lib ip65_atari.lib ip65_atarixl.lib ip65.atr

ip65.h:
	cp inc/$@ $@

ip65.lib ip65_tcp.lib:
	make -C ip65 $@
	cp ip65/$@ $@

ip65_c64.lib ip65_apple2.lib ip65_atari.lib ip65_atarixl.lib:
	make -C drivers $@
	cp drivers/$@ $@

ip65.%:
	make -C apps $@
	cp apps/$@ $@

clean:
	make -C apps clean
	-rm -f *.h *.lib *.d64 *.dsk *.atr *.zip
