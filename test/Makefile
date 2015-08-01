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
VICDRIVERLIB = ../drivers/vic20rrnet.lib

UDP =\
	dns \
	dottedquad \
	parsequerystring \
	sntp \
	tftp

TCP =\
	cifs \
	geturl \
	httpd \
	parser \
	ping \
	tcp

all:    $(UDP) $(TCP)
.PHONY: $(UDP) $(TCP)

$(addsuffix .prg,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .prg,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(addsuffix .bin,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .bin,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(addsuffix .vicprg,$(UDP)): IP65LIB = ../ip65/ip65.lib
$(addsuffix .vicprg,$(TCP)): IP65LIB = ../ip65/ip65_tcp.lib

$(foreach pgm,$(UDP) $(TCP),$(eval $(pgm): $(pgm).prg $(pgm).bin $(pgm).vicprg))

INCFILES =\
  ../inc/common.i \
  ../inc/commonprint.i \
  ../inc/net.i

prg: $(addsuffix .prg,$(UDP) $(TCP))

bin: $(addsuffix .bin,$(UDP) $(TCP))

vicprg: $(addsuffix .vicprg,$(UDP) $(TCP))

d64: ip65.d64

dsk: ip65.dsk

ip65:
	make -C ../ip65

drivers:
	make -C ../drivers

%.o: %.s
	ca65 $<

%.prg: %.o ip65 drivers $(INCFILES)
	ld65 -o $*.prg -C c64.cfg -m $*.c64.map -vm $< $(IP65LIB) $(C64DRIVERLIB) c64.lib

%.bin: %.o ip65 drivers $(INCFILES)
	ld65 -o $*.bin -C apple2.cfg -m $*.a2.map -vm $< $(IP65LIB) $(A2DRIVERLIB) apple2.lib

%.vicprg: %.o ip65 drivers $(INCFILES)
	ld65 -o $*.vicprg -C vic20-32k.cfg -m $*.vic.map -vm $< $(IP65LIB) $(VICDRIVERLIB) vic20.lib

ip65.d64: prg
	$(C1541) -format ip65,00 d64 $@
	$(C1541) -attach $@ -write dns.prg        dns,p
	$(C1541) -attach $@ -write dottedquad.prg dottedquad,p
	$(C1541) -attach $@ -write geturl.prg     geturl,p
	$(C1541) -attach $@ -write httpd.prg      httpd,p
	$(C1541) -attach $@ -write parser.prg     parser,p
	$(C1541) -attach $@ -write ping.prg       ping,p
	$(C1541) -attach $@ -write sntp.prg       sntp,p
	$(C1541) -attach $@ -write tcp.prg        tcp,p
	$(C1541) -attach $@ -write tftp.prg       tftp,p

ip65.dsk: bin
	cp prodos.dsk $@
	java -jar $(AC) -cc65 $@ dns        bin < dns.bin
	java -jar $(AC) -cc65 $@ dottedquad bin < dottedquad.bin
	java -jar $(AC) -cc65 $@ geturl     bin < geturl.bin
	java -jar $(AC) -cc65 $@ httpd      bin < httpd.bin
	java -jar $(AC) -cc65 $@ parser     bin < parser.bin
	java -jar $(AC) -cc65 $@ ping       bin < ping.bin
	java -jar $(AC) -cc65 $@ sntp       bin < sntp.bin
	java -jar $(AC) -cc65 $@ tcp        bin < tcp.bin
	java -jar $(AC) -cc65 $@ tftp       bin < tftp.bin

%-slotscan.o: %.s
	ca65 -D A2_SLOT_SCAN -o $@ $<

httpd-slotscan.bin: IP65LIB = ../ip65/ip65_tcp.lib

ip65demo.dsk: httpd.bin httpd-slotscan.bin
	cp dos33.dsk $@
	java -jar $(AC) -cc65 $@ webserver-slot3    B < httpd.bin
	java -jar $(AC) -cc65 $@ webserver-slotscan B < httpd-slotscan.bin

w5100_%.bin: ../supplement/w5100_%.s w5100_%_s.s w5100_%_c.c
	cl65 -o $@ -t apple2enh -m $(basename $@).map $^

w5100.dsk: w5100_udp.bin
	cp prodos.dsk $@
	java -jar $(AC) -cc65 $@ udp bin < w5100_udp.bin

clean:
	make -C ../ip65 clean
	make -C ../drivers clean
	-rm -f ../supplement/*.o
	-rm -f *.o *.prg *.bin *.vicprg *.map
	-rm -f ip65.d64 ip65.dsk ip65demo.dsk w5100.dsk
