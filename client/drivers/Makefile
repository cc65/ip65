AS=ca65
LD=ld65
AFLAGS=


%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<


DRIVERS=\
	apple2net.lib \
	c64net.lib \
  
all: $(DRIVERS)


apple2net.lib: a2print.o uthernet.o a2timer.o a2kernal.o a2input.o
	ar65 a apple2net.lib $^

c64net.lib: c64print.o rr-net.o c64timer.o c64kernal.o c64inputs.o
	ar65 a c64net.lib $^

clean:
	rm -f *.o
	rm -f apple2net.lib
	rm -f c64net.lib

distclean: clean
	rm -f *~
