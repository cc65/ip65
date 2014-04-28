AS     = ca65
LD     = ld65
AFLAGS =

%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<

# c64rrnet.lib   : C64 with RR-NET or clone at $de0x
# c64wiznet.lib  : C64 with Wiznet W5100 addressed at $df2x
# a2uther.lib    : Apple ][ with Uthernet in slot #3
# a2lancegs.lib  : Apple ][ with LANceGS
# vic20rrnet.lib : VIC20 with RR-NET or clone at $980x

DRIVERS=\
	c64rrnet.lib \
	c64wiznet.lib \
	a2uther.lib \
	a2lancegs.lib \
	vic20rrnet.lib

all: $(DRIVERS)

c64rrnet.lib: rr-net.o cs8900a.o c64zeropage.o c64print.o c64timer.o c64kernal.o c64input.o cbmcharconv.o
	ar65 a $@ $^

c64wiznet.lib: w5100.o c64zeropage.o c64print.o c64timer.o c64kernal.o c64input.o cbmcharconv.o
	ar65 a $@ $^

a2lancegs.lib: lan91c96.o  a2zeropage.o a2print.o a2timer.o a2kernal.o a2input.o a2charconv.o
	ar65 a $@ $^

a2uther.lib: uthernet.o cs8900a.o  a2zeropage.o a2print.o a2timer.o a2kernal.o a2input.o a2charconv.o
	ar65 a $@ $^

vic20rrnet.lib: vic20-rr-net.o cs8900a.o vic20zeropage.o vic20print.o vic20timer.o vic20kernal.o vic20input.o cbmcharconv.o
	ar65 a $@ $^

clean:
	-rm -f *.o
	-rm -f *.lib

distclean: clean
	-rm -f *~
