# c64rrnet.lib   : C64 with RR-Net or clone (default base addr: $de0x)
# c64eth64.lib   : C64 with ETH64 (default base addr: $de0x)
# a2uther.lib    : Apple ][ with Uthernet (default slot: #3)
# a2lancegs.lib  : Apple ][ with LANceGS (default slot: #3)
# a2uther2.lib   : Apple ][ with Uthernet II (default slot: #3)
# vic20rrnet.lib : VIC20 with RR-Net or clone (default base addr: $980x)

DRIVERS=\
	c64rrnet.lib \
	c64eth64.lib \
	a2uther.lib \
	a2lancegs.lib \
	a2uther2.lib \
	vic20rrnet.lib

all: $(DRIVERS)

%.o: %.s
	ca65 -D DYN_DRV=0 $<

C64OBJS=\
	contiki.o \
	c64zeropage.o \
	c64print.o \
	c64timer.o \
	c64kernal.o \
	c64input.o \
	cbmcharconv.o

A2OBJS=\
	contiki.o \
	a2zeropage.o \
	a2print.o \
	a2timer.o \
	a2kernal.o \
	a2input.o \
	a2charconv.o

VIC20OBJS=\
	contiki.o \
	vic20zeropage.o \
	vic20print.o \
	vic20timer.o \
	vic20kernal.o \
	vic20input.o \
	cbmcharconv.o

c64rrnet.lib: rr-net.o cs8900a.o $(C64OBJS)
	ar65 a $@ $^

c64eth64.lib: eth64.o lan91c96.o $(C64OBJS)
	ar65 a $@ $^

a2uther.lib: uthernet.o cs8900a.o $(A2OBJS)
	ar65 a $@ $^

a2lancegs.lib: lancegs.o lan91c96.o $(A2OBJS)
	ar65 a $@ $^

a2uther2.lib: uthernet2.o w5100.o $(A2OBJS)
	ar65 a $@ $^

vic20rrnet.lib: vic20-rr-net.o cs8900a.o $(VIC20OBJS)
	ar65 a $@ $^

clean:
	-rm -f *.o
	-rm -f *.lib
