TARGET=c64


.PHONY: ip65 drivers test clean distclean nb65 examples


all: ip65 drivers test nb65  examples

ip65:
	make -C ip65 all

drivers:
	make -C drivers all

examples:
	make -C examples all

test:
	make -C test TARGET=$(TARGET) all

nb65:
	make -C nb65 all

clean:
	make -C ip65 clean
	make -C drivers clean
	make -C test clean
	make -C nb65 clean
	make -C kipper clean


distclean:
	make -C ip65 distclean
	make -C drivers clean
	make -C test distclean
	make -C nb65 distclean
	make -C kipper distclean
	rm -f *~
