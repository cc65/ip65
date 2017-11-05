# For assembler programs
# ----------------------
# c64rrnet.lib   : C64 with RR-Net (or clone) (default base addr: $de0x)
# c64eth64.lib   : C64 with ETH64 (default base addr: $de0x)
# c64wiz811.lib  : C64 with WIZ811MJ (default base addr: $de0x)
# c64combo.lib   : C64 with RR-Net or ETH64 or WIZ811MJ (default base addr: $de0x)
# a2uther.lib    : Apple ][ with Uthernet (default slot: #3)
# a2lancegs.lib  : Apple ][ with LANceGS (default slot: #3)
# a2uther2.lib   : Apple ][ with Uthernet II (default slot: #3)
# a2combo.lib    : Apple ][ with Uthernet or LANceGS or Uthernet II (default slot: #3)
# atrdragon.lib  : ATARI 8-bit with Dragon Cart (default base addr: $d500)
# vic20rrnet.lib : VIC20 with RR-Net or clone (default base addr: $980x)

# For C programs
# --------------
# ip65_c64.lib    : C64 with RR-Net or ETH64 or WIZ811MJ (default base addr: $de0x)
# ip65_apple2.lib : Apple ][ with Uthernet or LANceGS or Uthernet II (default slot: #3)
# ip65_atari.lib  : ATARI 8-bit with Dragon Cart (default base addr: $d500)

DRIVERS=\
	c64rrnet.lib \
	c64eth64.lib \
	c64wiz811.lib \
	c64combo.lib \
	ip65_c64.lib \
	a2uther.lib \
	a2lancegs.lib \
	a2uther2.lib \
	a2combo.lib \
	ip65_apple2.lib \
	atrdragon.lib \
	ip65_atari.lib \
	vic20rrnet.lib

all: $(DRIVERS)

$(DRIVERS):
	ar65 a $@ $^

%.o: %.s
	ca65 -D DYN_DRV=0 $<

C64OBJS=\
	c64print.o \
	c64timer.o \
	c64kernal.o \
	c64input.o \
	c64filteredinput.o \
	c64vt100.o \
	cbmcharconv.o

C64_OBJS=\
	c64timer.o \
	c64_input.o

A2OBJS=\
	a2print.o \
	a2timer.o \
	a2kernal.o \
	a2input.o \
	a2filteredinput.o \
	a2vt100.o \
	a2charconv.o

A2_OBJS=\
	a2_timer.o \
	a2_input.o

ATROBJS=\
	atrprint.o \
	atrtimer.o \
	atrkernal.o \
	atrinput.o \
	atrfilteredinput.o \
	atrvt100.o \
	atrvt100font.o \
	atrcharconv.o

ATR_OBJS=\
	atrtimer.o \
	atr_input.o

VIC20OBJS=\
	vic20print.o \
	vic20timer.o \
	vic20kernal.o \
	vic20input.o \
	vic20filteredinput.o \
	vic20vt100.o \
	cbmcharconv.o

CS8900AOBJS=\
	cs8900a.o \
	cs8900adriver.o \
	ethernet.o

LAN91C96OBJS=\
	lan91c96.o \
	lan91c96driver.o \
	ethernet.o

W5100OBJS=\
	w5100.o \
	w5100driver.o \
	ethernet.o

COMBOOBJS=\
	cs8900a.o \
	lan91c96.o \
	w5100.o \
	ethernetcombo.o

c64rrnet.lib: c64init.o rr-net.o $(CS8900AOBJS) $(C64OBJS)

c64eth64.lib: c64init.o eth64.o $(LAN91C96OBJS) $(C64OBJS)

c64wiz811.lib: c64init.o wiz811mj.o $(W5100OBJS) $(C64OBJS)

c64combo.lib: c64init.o rr-net.o eth64.o wiz811mj.o $(COMBOOBJS) $(C64OBJS)

ip65_c64.lib: c64init.o rr-net.o eth64.o wiz811mj.o $(COMBOOBJS) $(C64_OBJS)

a2uther.lib: a2init.o uthernet.o $(CS8900AOBJS) $(A2OBJS)

a2lancegs.lib: a2init.o lancegs.o $(LAN91C96OBJS) $(A2OBJS)

a2uther2.lib: a2init.o uthernet2.o $(W5100OBJS) $(A2OBJS)

a2combo.lib: a2initcombo.o uthernet.o lancegs.o uthernet2.o $(COMBOOBJS) $(A2OBJS)

ip65_apple2.lib: a2initcombo.o uthernet.o lancegs.o uthernet2.o $(COMBOOBJS) $(A2_OBJS)

atrdragon.lib: atrinit.o dragoncart.o $(CS8900AOBJS) $(ATROBJS)

ip65_atari.lib: atrinit.o dragoncart.o $(CS8900AOBJS) $(ATR_OBJS)

vic20rrnet.lib: vic20init.o vic20-rr-net.o $(CS8900AOBJS) $(VIC20OBJS)

clean:
	-rm -f *.o
	-rm -f *.lib
