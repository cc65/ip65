
.PHONY: ip65 drivers test clean distclean kipperterm2  examples carts  basic wiznet


all: ip65 drivers test carts  examples basic kipperterm2 wiznet

ip65:
	make -C ip65 all

drivers:
	make -C drivers all

examples:
	make -C examples all



test:
	make -C test TARGET=$(TARGET) all


kipperterm2:
	make -C kipperterm2 all


carts:
	make -C carts all

basic:
	make -C basic all

wiznet:
	make -C wiznet all


clean:
	make -C ip65 clean

	make -C drivers clean
	make -C test clean
	make -C carts clean

	make -C kipperterm2 clean

	make -C basic clean  	


distclean:
	make -C ip65 distclean

	make -C drivers clean
	make -C test distclean

	make -C carts distclean

	make -C kipperterm2 distclean

	make -C basic distclean  	

	rm -f *~
