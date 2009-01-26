.PHONY: client clean dist distclean

all: client dist

client:
	make -C client all

clean:	
	make -C client clean

dist:
	ruby dist\make_dist.rb
  
distclean:
	make -C client distclean
	rm -f *~
