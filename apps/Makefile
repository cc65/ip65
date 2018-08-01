# Build for Cirrus Logic CS8900A based devices:
# make eth=cl

# Build for Standard Microsystems LAN91C96 based devices:
# make eth=sm

# Build for WIZnet W5100 based devices:
# make eth=wn

ifeq ($(eth),cl)
  C64DRIVERLIB = ../drivers/c64rrnet.lib
  A2DRIVERLIB  = ../drivers/a2uther.lib
else ifeq ($(eth),sm)
  C64DRIVERLIB = ../drivers/c64eth64.lib
  A2DRIVERLIB  = ../drivers/a2lancegs.lib
else ifeq ($(eth),wn)
  C64DRIVERLIB = ../drivers/c64wiz811.lib
  A2DRIVERLIB  = ../drivers/a2uther2.lib
else
  C64DRIVERLIB = ../drivers/c64combo.lib
  A2DRIVERLIB  = ../drivers/a2combo.lib
endif
ATRDRIVERLIB = ../drivers/atrdragon.lib

C64_DRIVERLIB = ../drivers/ip65_c64.lib
A2_DRIVERLIB  = ../drivers/ip65_apple2.lib
ATR_DRIVERLIB = ../drivers/ip65_atari.lib

UDP =\
	date65

TCP =\
	hfs65 \
	telnet65

date65.bin hfs65.bin: CL65FLAGS = --start-addr 0x0C00 apple2enh-iobuf-0800.o

telnet65.com: ATARI_CFG = atrtelnet.cfg

all:    $(UDP) $(TCP)
.PHONY: $(UDP) $(TCP)

$(addsuffix .prg,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .prg,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(addsuffix .bin,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .bin,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(addsuffix .com,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .com,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(foreach pgm,$(UDP) $(TCP),$(eval $(pgm): $(pgm).prg $(pgm).bin $(pgm).com))

prg: $(addsuffix .prg,$(UDP) $(TCP))

bin: $(addsuffix .bin,$(UDP) $(TCP))

com: $(addsuffix .com,$(UDP) $(TCP))

d64: ip65.d64

dsk: ip65.dsk

atr: ip65.atr

ip65:
	make -C ../ip65

drivers:
	make -C ../drivers

BUILDS = ip65 drivers

CC65 := $(shell cl65 --print-target-path)

ATARI_CFG = atari.cfg

%.s.o: %.s
	ca65 -o $@ $<

%.o: %.c

%.prg: %.s.o $(BUILDS)
	ld65 -o $*.prg -C c64.cfg -m $*.c64.map -vm $< $(IP65LIB) $(C64DRIVERLIB) c64.lib

%.bin: %.s.o $(BUILDS)
	ld65 -o $*.bin -C apple2.cfg -m $*.a2.map -vm $< $(IP65LIB) $(A2DRIVERLIB) apple2.lib

%.com: %.s.o $(BUILDS)
	ld65 -o $*.com -C $(ATARI_CFG) -m $*.atr.map -vm $< $(IP65LIB) $(ATRDRIVERLIB) atari.lib

%.prg: %.c $(BUILDS)
	cl65 -o $*.prg -Or -t c64 $(CL65FLAGS) -m $*.c64.map -vm $(filter-out $(BUILDS),$^) $(IP65LIB) $(C64_DRIVERLIB)

%.bin: %.c $(BUILDS)
	cl65 -o $*.bin -Or -t apple2enh $(CL65FLAGS) -m $*.a2.map -vm $(filter-out $(BUILDS),$^) $(IP65LIB) $(A2_DRIVERLIB)

%.com: %.c $(BUILDS)
	cl65 -o $*.com -Or -t atari $(CL65FLAGS) -m $*.atr.map -vm $(filter-out $(BUILDS),$^) $(IP65LIB) $(ATR_DRIVERLIB)

ip65.d64: prg
	$(C1541) -format ip65,00 d64 $@
	$(C1541) -attach $@ -write date65.prg   date65,p
	$(C1541) -attach $@ -write hfs65.prg    hfs65,p
	$(C1541) -attach $@ -write telnet65.prg telnet65,p

ip65.dsk: bin
	cp ../build/prodos.dsk $@
	java -jar $(AC) -as $@ date65            < date65.bin
	java -jar $(AC) -p  $@ date65.system sys < $(CC65)/apple2enh/util/loader.system
	java -jar $(AC) -as $@ hfs65             < hfs65.bin
	java -jar $(AC) -p  $@ hfs65.system  sys < $(CC65)/apple2enh/util/loader.system
	java -jar $(AC) -as $@ telnet65          < telnet65.bin

ip65.atr: com
	mkdir atr
	cp ../build/dos.sys atr/dos.sys
	cp ../build/dup.sys atr/dup.sys
	cp date65.com       atr/date65.com
	cp telnet65.com     atr/telnet65.com
	$(DIR2ATR) -b Dos25 1040 $@ atr
	rm -r atr

clean:
	make -C ../ip65 clean
	make -C ../drivers clean
	-rm -f *.o *.prg *.bin *.com *.map
	-rm -f ip65.d64 ip65.dsk ip65.atr
