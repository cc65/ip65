
.include "../inc/common.i"

.import copymem
.importzp copy_src
.importzp copy_dest

.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

.word basicstub		; load address

basicstub:
	.word @nextline
	.word 2003
	.byte $9e 
	.byte <(((init / 1000) .mod 10) + $30)
	.byte <(((init / 100 ) .mod 10) + $30)
	.byte <(((init / 10  ) .mod 10) + $30)
	.byte <(((init       ) .mod 10) + $30)
	.byte 0
@nextline:
	.word 0

init:

;copy BASIC to RAM
  ldax #$A000
  stax copy_src
  stax copy_dest
  ldax #$2000
  jsr copymem

;copy cart data from end of file to $8000 (RAM)
  ldax #cart_data
  stax copy_src
  ldax #$8000
  stax copy_dest
  ldax #$2000
  jsr copymem

;swap out the cartridge (also swaps out BASIC)

  lda $01
  and #$fe	;reset bit 0
  sta $01 

;execute the cartridge from RAM  
  jmp ($8002)	
  

.bss

cart_data:	;this should point to where the cart data gets appended.
	.res $2000