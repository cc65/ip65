# Build for Cirrus Logic CS8900A based devices:
# make eth=cl

# Build for Standard Microsystems LAN91C96 based devices:
# make eth=sm

# Build for WIZnet W5100 based devices:
# make eth=wn

ifeq ($(eth),cl)
  C64DRIVERLIB = ../drivers/c64rrnet.lib
  A2DRIVERLIB  = ../drivers/a2uther.lib
  ATRDRIVERLIB = ../drivers/atrdragon.lib
  VICDRIVERLIB = ../drivers/vic20rrnet.lib
else ifeq ($(eth),sm)
  C64DRIVERLIB = ../drivers/c64eth64.lib
  A2DRIVERLIB  = ../drivers/a2lancegs.lib
else ifeq ($(eth),wn)
  A2DRIVERLIB  = ../drivers/a2uther2.lib
else
  C64DRIVERLIB = ../drivers/c64combo.lib
  A2DRIVERLIB  = ../drivers/a2combo.lib
  ATRDRIVERLIB = ../drivers/atrdragon.lib
  VICDRIVERLIB = ../drivers/vic20rrnet.lib
endif

# See https://vice-emu.sourceforge.net/
C1541 ?= c1541

# See https://applecommander.github.io/
AC ?= ac.jar

# See https://www.horus.com/~hias/atari/
DIR2ATR ?= dir2atr

UDP =\
	dns \
	dottedquad \
	parsequerystring \
	sntp \
	tftp \
	timer \
	udp \
	vt100

TCP =\
	geturl \
	httpd \
	math \
	parser \
	ping \
	tcp

C_PGM := $(foreach pgm,$(UDP) $(TCP),$(basename $(wildcard $(pgm).c)))

all:    $(UDP) $(TCP)
.PHONY: $(UDP) $(TCP)

$(addsuffix .prg,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .prg,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(addsuffix .bin,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .bin,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(addsuffix .com,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .com,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(addsuffix .xl.com,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .xl.com,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(addsuffix .vicprg,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .vicprg,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(foreach pgm,$(UDP) $(TCP),$(eval $(pgm): $(pgm).prg $(pgm).bin $(pgm).com))

$(foreach pgm,$(C_PGM),$(eval $(pgm): $(pgm).xl.com))

httpd-slotscan.bin: IP65LIB = ../ip65/ip65_tcp.lib

prg: $(addsuffix .prg,$(UDP) $(TCP))

bin: $(addsuffix .bin,$(UDP) $(TCP)) httpd-slotscan.bin

com: $(addsuffix .com,$(UDP) $(TCP))

xl.com: $(addsuffix .xl.com,$(C_PGM))

vicprg: $(addsuffix .vicprg,$(UDP) $(TCP))

d64: ip65test.d64

dsk: ip65test.dsk

atr: ip65test.atr

ip65:
	make -C ../ip65

drivers:
	make -C ../drivers

ATARI_CFG = atari.cfg
vt100.com: ATARI_CFG = ../apps/atrtelnet.cfg

%.o: %.s
	ca65 $<

%-slotscan.o: %.s
	ca65 -D A2_SLOT_SCAN -o $@ $<

%.o: %.c

%.prg: %.o ip65 drivers
	ld65 -o $*.prg -C c64.cfg -m $*.prg.map -vm $< $(IP65LIB) $(C64DRIVERLIB) c64.lib

%.bin: %.o ip65 drivers
	ld65 -o $*.bin -C apple2.cfg -m $*.bin.map -vm $< $(IP65LIB) $(A2DRIVERLIB) apple2.lib

%.com: %.o ip65 drivers
	ld65 -o $*.com -C $(ATARI_CFG) -m $*.com.map -vm $< $(IP65LIB) $(ATRDRIVERLIB) atari.lib

%.vicprg: %.o ip65 drivers
	ld65 -o $*.vicprg -C vic20-32k.cfg -m $*.vicprg.map -vm $< $(IP65LIB) $(VICDRIVERLIB) vic20.lib

%.prg: %.c ip65 drivers
	cl65 -o $*.prg -O -t c64 -m $*.prg.map -vm $< $(wildcard $**.s) $(IP65LIB) ../drivers/ip65_c64.lib

%.bin: %.c ip65 drivers
	cl65 -o $*.bin -O -t apple2 -m $*.bin.map -vm $< $(wildcard $**.s) $(IP65LIB) ../drivers/ip65_apple2.lib

%.com: %.c ip65 drivers
	cl65 -o $*.com -O -t atari -m $*.com.map -vm $< $(wildcard $**.s) $(IP65LIB) ../drivers/ip65_atari.lib

%.xl.com: %.c ip65 drivers
	cl65 -o $*.xl.com -O -t atarixl -m $*.xl.com.map -vm $< $(wildcard $**.s) $(IP65LIB) ../drivers/ip65_atarixl.lib

ip65test.d64: prg
	$(C1541) -format ip65,00 d64 $@
	$(C1541) -attach $@ -write dns.prg        dns,p
	$(C1541) -attach $@ -write dottedquad.prg dottedquad,p
	$(C1541) -attach $@ -write geturl.prg     geturl,p
	$(C1541) -attach $@ -write httpd.prg      httpd,p
	$(C1541) -attach $@ -write math.prg       math,p
	$(C1541) -attach $@ -write parser.prg     parser,p
	$(C1541) -attach $@ -write ping.prg       ping,p
	$(C1541) -attach $@ -write sntp.prg       sntp,p
	$(C1541) -attach $@ -write tcp.prg        tcp,p
	$(C1541) -attach $@ -write tftp.prg       tftp,p
	$(C1541) -attach $@ -write timer.prg      timer,p
	$(C1541) -attach $@ -write udp.prg        udp,p
	$(C1541) -attach $@ -write vt100.prg      vt100,p

ip65test.dsk: bin
	cp ../build/prodos.dsk $@
	java -jar $(AC) -as $@ dns            < dns.bin
	java -jar $(AC) -as $@ geturl         < geturl.bin
	java -jar $(AC) -as $@ httpd          < httpd.bin
	java -jar $(AC) -as $@ httpd.slotscan < httpd-slotscan.bin
	java -jar $(AC) -as $@ math           < math.bin
	java -jar $(AC) -as $@ parser         < parser.bin
	java -jar $(AC) -as $@ ping           < ping.bin
	java -jar $(AC) -as $@ sntp           < sntp.bin
	java -jar $(AC) -as $@ tcp            < tcp.bin
	java -jar $(AC) -as $@ tftp           < tftp.bin
	java -jar $(AC) -as $@ udp            < udp.bin
	java -jar $(AC) -as $@ vt100          < vt100.bin

ip65test.atr: com xl.com
	mkdir atr
	cp ../build/dos.sys atr/dos.sys
	cp ../build/dup.sys atr/dup.sys
	cp dns.com          atr/dns.com
	cp geturl.com       atr/geturl.com
	cp httpd.com        atr/httpd.com
	cp math.com         atr/math.com
	cp parser.com       atr/parser.com
	cp ping.com         atr/ping.com
	cp sntp.com         atr/sntp.com
	cp tcp.com          atr/tcp.com
	cp tcp.xl.com       atr/tcpxl.com
	cp tftp.com         atr/tftp.com
	cp timer.com        atr/timer.com
	cp timer.xl.com     atr/timerxl.com
	cp udp.com          atr/udp.com
	cp udp.xl.com       atr/udpxl.com
	cp vt100.com        atr/vt100.com
	$(DIR2ATR) -b Dos25 1040 $@ atr
	rm -r atr

%.exe: %.c
	cl /Fe:$@ $^

clean:
	make -C ../ip65 clean
	make -C ../drivers clean
	-rm -f *.o *.prg *.bin *.com *.vicprg *.map *.obj *.exe
	-rm -f ip65test.d64 ip65test.dsk ip65test.atr
