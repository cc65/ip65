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

UDP =\
	date

TCP =\
	telnet65

all:    $(UDP) $(TCP)
.PHONY: $(UDP) $(TCP)

$(addsuffix .prg,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .prg,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(addsuffix .bin,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .bin,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(addsuffix .com,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .com,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(foreach pgm,$(UDP) $(TCP),$(eval $(pgm): $(pgm).prg $(pgm).bin $(pgm).com))

INCFILES =\
  ../inc/common.i \
  ../inc/commonprint.i \
  ../inc/net.i

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

ATARI_CFG = atari.cfg
telnet65.com: ATARI_CFG = atrtelnet.cfg

%.o: %.s
	ca65 $<

%.o: %.c

%.prg: %.o ip65 drivers $(INCFILES)
	ld65 -o $*.prg -C c64.cfg -m $*.c64.map -vm $< $(IP65LIB) $(C64DRIVERLIB) c64.lib

%.bin: %.o ip65 drivers $(INCFILES)
	ld65 -o $*.bin -C apple2.cfg -m $*.a2.map -vm $< $(IP65LIB) $(A2DRIVERLIB) apple2.lib

%.com: %.o ip65 drivers $(INCFILES)
	ld65 -o $*.com -C $(ATARI_CFG) -m $*.atr.map -vm $< $(IP65LIB) $(ATRDRIVERLIB) atari.lib

%.prg: %.c ip65 drivers $(INCFILES)
	cl65 -o $*.prg -O -t c64 -m $*.c64.map -vm $< $(IP65LIB) ../drivers/ip65_c64.lib
	rm $*.o

%.bin: %.c ip65 drivers $(INCFILES)
	cl65 -o $*.bin -O -t apple2enh -m $*.a2.map -vm $< $(IP65LIB) ../drivers/ip65_apple2.lib
	rm $*.o

%.com: %.c ip65 drivers $(INCFILES)
	cl65 -o $*.com -O -t atari -m $*.atr.map -vm $< $(IP65LIB) ../drivers/ip65_atari.lib
	rm $*.o

ip65.d64: prg
	$(C1541) -format ip65,00 d64 $@
	$(C1541) -attach $@ -write date.prg     date,p
	$(C1541) -attach $@ -write telnet65.prg telnet65,p

ip65.dsk: bin
	cp prodos.dsk $@
	java -jar $(AC) -cc65 $@ date     bin < date.bin
	java -jar $(AC) -cc65 $@ telnet65 bin < telnet65.bin

ip65.atr: com
	mkdir atr
	cp dos.sys      atr/dos.sys
	cp dup.sys      atr/dup.sys
	cp date.com     atr/date.com
	cp telnet65.com atr/telnet65.com
	$(DIR2ATR) -b Dos25 1040 $@ atr
	rm -r atr

clean:
	make -C ../ip65 clean
	make -C ../drivers clean
	-rm -f ../supplement/*.o
	-rm -f *.o *.prg *.bin *.com *.map
	-rm -f ip65.d64 ip65.dsk ip65.atr
