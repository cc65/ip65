# For assembler programs
# ----------------------
# c64rrnet.lib   : C64 with RR-Net (or clone) (default base addr: $de0x)
# c64eth64.lib   : C64 with ETH64 (default base addr: $de0x)
# c64combo.lib   : C64 with RR-Net or ETH64 (default base addr: $de0x)
# a2uther.lib    : Apple ][ with Uthernet (default slot: #3)
# a2lancegs.lib  : Apple ][ with LANceGS (default slot: #3)
# a2uther2.lib   : Apple ][ with Uthernet II (default slot: #3)
# a2combo.lib    : Apple ][ with Uthernet or LANceGS or Uthernet II (default slot: #3)
# atrdragon.lib  : ATARI 8-bit with Dragon Cart (default base addr: $d500)
# vic20rrnet.lib : VIC20 with RR-Net (or clone) (default base addr: $980x)

# For C programs
# --------------
# ip65_c64.lib     : C64 with RR-Net or ETH64 (default base addr: $de0x)
# ip65_apple2.lib  : Apple ][ with Uthernet or LANceGS or Uthernet II (default slot: #3)
# ip65_atari.lib   : ATARI 8-bit with Dragon Cart (default base addr: $d500)
# ip65_atarixl.lib : ATARI XL with Dragon Cart (default base addr: $d500)

DRIVERS=\
	c64rrnet.lib \
	c64eth64.lib \
	c64combo.lib \
	ip65_c64.lib \
	a2uther.lib \
	a2lancegs.lib \
	a2uther2.lib \
	a2combo.lib \
	ip65_apple2.lib \
	ip65_apple2_uther2.lib \
	atrdragon.lib \
	ip65_atari.lib \
	ip65_atarixl.lib \
	vic20rrnet.lib

all: $(DRIVERS)

$(DRIVERS):
	ar65 a $@ $^

%.o: %.s
	ca65 $<

%.xl.o: %.s
	ca65 -o $*.xl.o -t atarixl $<

C64OBJS=\
	c64print.o \
	c64timer.o \
	c64kernal.o \
	c64input.o \
	c64filteredinput.o \
	c64vt100.o \
	cbmcharconv.o

C64_OBJS=\
	clk_timer.o \
	c64_cps.o \
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
	clk_timer.o \
	atr_input.o

ATRXL_OBJS=\
	clk_timer.xl.o \
	atr_input.xl.o

VIC20OBJS=\
	vic20print.o \
	vic20timer.o \
	vic20kernal.o \
	vic20input.o \
	vic20filteredinput.o \
	vic20vt100.o \
	cbmcharconv.o

CS8900AOBJS=\
	cs8900adriver.o \
	ethernet.o

LAN91C96OBJS=\
	lan91c96driver.o \
	ethernet.o

W5100OBJS=\
	w5100driver.o \
	ethernet.o

c64rrnet.lib: rr-net.o $(CS8900AOBJS) c64init.o $(C64OBJS)

c64eth64.lib: eth64.o $(LAN91C96OBJS) c64init.o $(C64OBJS)

c64combo.lib: rr-net.o eth64.o c64combo.o c64init.o $(C64OBJS)

ip65_c64.lib: rr-net.o eth64.o c64combo.o c64init.o $(C64_OBJS)

a2uther.lib: uthernet.o $(CS8900AOBJS) a2init.o $(A2OBJS)

a2lancegs.lib: lancegs.o $(LAN91C96OBJS) a2init.o $(A2OBJS)

a2uther2.lib: uthernet2.o $(W5100OBJS) a2init.o $(A2OBJS)

a2combo.lib: uthernet.o lancegs.o uthernet2.o a2combo.o a2init.o $(A2OBJS)

ip65_apple2.lib: uthernet.o lancegs.o uthernet2.o a2combo.o a2init.o $(A2_OBJS)

ip65_apple2_uther2.lib: uthernet2.o $(W5100OBJS) a2init.o $(A2_OBJS)

atrdragon.lib: dragoncart.o $(CS8900AOBJS) atrinit.o $(ATROBJS)

ip65_atari.lib: dragoncart.o $(CS8900AOBJS) atrinit.o $(ATR_OBJS)

ip65_atarixl.lib: dragoncart.o $(CS8900AOBJS) atrinit.o $(ATRXL_OBJS)

vic20rrnet.lib: vic20-rr-net.o $(CS8900AOBJS) vic20init.o $(VIC20OBJS)

clean:
	-rm -f *.o
	-rm -f *.lib
