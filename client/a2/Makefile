CC=cl65
AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=



IP65LIB=../ip65/ip65.lib
IP65TCPLIB=../ip65/ip65_tcp.lib
A2UTHERLIB=../drivers/a2uther.lib

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\

all: \
	ip65 \
	drivers \
	amper.dsk \


ip65:
	make -C ../ip65 all

drivers:
	make -C ../drivers all

%.o: %.s
	$(AS) $(AFLAGS)  $<

#tokenize_asoft comes from http://www.deater.net/weave/vmwprod/apple/dos33fs.html
%.bas:	%.applesoft
	tokenize_asoft < $*.applesoft > $*.bas

%.pg2: %.o $(IP65LIB) $(A2UTHERLIB) $(INCFILES) ../cfg/a2bin.cfg
	$(LD) -vm --mapfile $*.map -C ../cfg/a2bin.cfg -o $*.pg2  $(AFLAGS) $< $(IP65LIB) $(A2UTHERLIB)

amper.dsk: autoexec.pg2 autoexec.bas amper.pg2
		ripxplore.rb amper.dsk --init AppleDos
		ripxplore.rb amper.dsk -a autoexec.pg2 -t AppleBinary
		ripxplore.rb amper.dsk -a amper.pg2 -t AppleBinary
		cp autoexec.bas hello
		ripxplore.rb amper.dsk -a hello -t Applesoft
		rm hello
	
clean:
	rm -f *.o *.pg2 *.map *.lst 
	rm -f ip65test.dsk
	rm -f amper.dsk

distclean: clean
	rm -f *~
