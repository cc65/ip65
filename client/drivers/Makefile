AS=ca65
LD=ld65
AFLAGS=


%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<



DRIVERS=\
	apple2prog.lib \
	c64rrnet.lib \
	c64wiznet.lib \

  
all: $(DRIVERS)


apple2prog.lib: a2print.o uthernet.o a2timer.o a2kernal.o a2input.o a2charconv.o cs8900a.o
	ar65 a $@ $^

c64rrnet.lib: c64print.o rr-net.o c64timer.o c64kernal.o c64inputs.o c64_disk_access.o c64charconv.o c64_vt100.o cs8900a.o
	ar65 a $@ $^

c64wiznet.lib: w5100.o c64print.o c64timer.o  c64kernal.o c64inputs.o c64_disk_access.o c64charconv.o c64_vt100.o 
	ar65 a $@ $^


#	ar65 a $@ $^


clean:
	rm -f *.o
	rm -f *.lib

distclean: clean
	rm -f *~
