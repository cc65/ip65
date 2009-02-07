CC=cl65
AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\
  ../inc/menu.i\

%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s $(INCFILES) 
	$(AS) $(AFLAGS) $<

IP65LIB=../ip65/ip65.lib

C64NETLIB=../drivers/c64net.lib
APPLE2NETLIB=../drivers/apple2net.lib

BOOTA2.PG2=../../server/boot/BOOTA2.PG2

  
all: \
	rrnetboot.bin \
	utherboot.dsk \
	$(BOOTA2.PG2) \  
  
rrnetboot.bin: rrnetboot.o $(IP65LIB) $(C64NETLIB) $(INCFILES) ../cfg/rrbin.cfg
	$(LD) -m rrnetboot.map -C ../cfg/rrbin.cfg -o rrnetboot.bin  $(AFLAGS) $< $(IP65LIB) $(C64NETLIB)  
	ruby fix_cart.rb rrnetboot.bin
  
utherboot.pg2: utherboot.o $(IP65LIB) $(APPLE2NETLIB) $(INCFILES) ../cfg/a2language_card.cfg
	$(LD) -m utherboot.map -C ../cfg/a2language_card.cfg -o utherboot.pg2  $(AFLAGS) $< $(IP65LIB) $(APPLE2NETLIB)  

utherboot.dsk: utherboot.pg2
	ripxplore.rb --init AppleDos utherboot.dsk -a utherboot.pg2 -t AppleBinary
	ripxplore.rb utherboot.dsk -a hello -t Applesoft

$(BOOTA2.PG2): bootmenu.o $(IP65LIB) $(APPLE2NETLIB) $(INCFILES) ../cfg/a2language_card.cfg
	$(LD) -m bootmenu.map -C ../cfg/a2language_card.cfg -o $(BOOTA2.PG2)  $(AFLAGS) $< $(IP65LIB) $(APPLE2NETLIB)  
  
clean:
	rm -f *.o
	rm -f rrnetboot.bin rrnetboot.map 
	rm -f utherboot.pg2 utherboot.map utherboot.dsk
	rm -f $(BOOTA2.PG2)

distclean: clean
	rm -f *~
