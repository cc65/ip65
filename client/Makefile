TARGET=c64


.PHONY: ip65 drivers test clients clean distclean


all: ip65 drivers test clients

ip65:
	make -C ip65 all

drivers:
	make -C drivers all

test:
	make -C test TARGET=$(TARGET) all

clients:
	make -C clients all

clean:
	make -C ip65 clean
	make -C drivers clean
	make -C test clean
	make -C clients clean

distclean:
	make -C ip65 distclean
	make -C drivers clean
	make -C test distclean
	make -C clients distclean
	rm -f *~
