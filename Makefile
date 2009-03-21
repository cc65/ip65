.PHONY: client clean dist distclean

all: client dist

client:
	make -C client all

clean:	
	make -C client clean
	rm -rf dist/netboot65
	rmdir dist/netboot65
	rm -f dist/*.zip
  
dist:
	ruby dist/make_dist.rb

dist-ip65:
	rm  -rf dist/ip65
	ruby dist/make_dist_ip65.rb	
  
distclean:
	make -C client distclean
	rm -f *~
