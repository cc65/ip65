TARGET=c64


.PHONY: ip65 drivers test clean distclean carts examples


all: ip65 drivers test carts  examples

ip65:
	make -C ip65 all

drivers:
	make -C drivers all

examples:
	make -C examples all

test:
	make -C test TARGET=$(TARGET) all

carts:
	make -C carts all

clean:
	make -C ip65 clean
	make -C drivers clean
	make -C test clean
	make -C carts clean

distclean:
	make -C ip65 distclean
	make -C drivers clean
	make -C test distclean
	make -C carts distclean
	rm -f *~
