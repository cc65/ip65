AS=ca65
LD=ld65
AFLAGS=


%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<


DRIVERS=\
	apple2prog.lib \
	c64prog.lib \
	c64nb65.lib \
  
all: $(DRIVERS)


apple2prog.lib: a2print.o uthernet.o a2timer.o a2kernal.o a2input.o a2charconv.o
	ar65 a $@ $^

c64prog.lib: c64print.o rr-net.o c64timer.o c64kernal.o c64inputs.o c64_disk_access.o c64charconv.o
	ar65 a $@ $^

c64nb65.lib: c64print.o rr-net.o c64timer_nb65.o c64kernal.o c64inputs.o c64_disk_access.o c64charconv.o
	ar65 a $@ $^

clean:
	rm -f *.o
	rm -f *.lib

distclean: clean
	rm -f *~
