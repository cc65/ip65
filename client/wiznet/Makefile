

all: kipperwizdisk.d64

#../basic/wizkb.prg ../basic/wizbob.prg

kipperwizdisk.d64: ../carts/kkwiz.prg ../kipperterm2/kt2wiz.prg 
	ripxplore.rb --init CbmDos $@ -a ../carts/kkwiz.prg
	ripxplore.rb $@ -a ../kipperterm2/addresses.txt -t C64Seq
	ripxplore.rb $@ -a ../kipperterm2/abe -t C64Prg
	ripxplore.rb $@ -a ../kipperterm2/kt2wiz.prg -t C64Prg
	ripxplore.rb $@ -a ../examples/webnoter.prg -t C64Prg	
	cp $@ ../../server/boot/
