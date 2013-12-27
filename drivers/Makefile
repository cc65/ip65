AS=ca65
LD=ld65
AFLAGS=

%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<

# a2uther.lib : Apple //, with an Uthernet card (cs8900a chipset) in slot #3
# a2lancegs.lib : Apple //, with a LANceGS card (lan91c96)
# c64rrnet.lib : C64 with RR-NET or clone at $de0x
# c64wiznet.lib : C64 with Wiznet W5100 addressed at $df2x
# vic20rrnet.lib : C64 with RR-NET or clone at $980x

DRIVERS=\
	a2uther.lib \
	a2lancegs.lib \
	c64rrnet.lib \
	c64wiznet.lib \
	vic20rrnet.lib

all: $(DRIVERS)

a2lancegs.lib: a2print.o lan91c96.o a2timer.o a2kernal.o a2input.o a2charconv.o a2_zero_page.o
	ar65 a $@ $^

a2uther.lib: a2print.o uthernet.o a2timer.o a2kernal.o a2input.o a2charconv.o cs8900a.o a2_zero_page.o
	ar65 a $@ $^

c64rrnet.lib: c64print.o rr-net.o c64timer.o c64kernal.o c64inputs.o petscii_charconv.o cs8900a.o generic_zero_page.o
	ar65 a $@ $^

c64wiznet.lib: w5100.o c64print.o c64timer.o c64kernal.o c64inputs.o petscii_charconv.o generic_zero_page.o
	ar65 a $@ $^

vic20rrnet.lib: vic20print.o vic20-rr-net.o vic20timer.o vic20input.o petscii_charconv.o cs8900a.o generic_zero_page.o
	ar65 a $@ $^

clean:
	-rm -f *.o
	-rm -f *.lib

distclean: clean
	-rm -f *~
