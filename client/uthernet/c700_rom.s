.include "../inc/common.i"
.include "../inc/a2keycodes.i"

.import print_a
.import print_cr

pptr=$04  ;temp pointer for printing from


.segment        "C700"

;Autostart 'signature' bytes - make this rom look like a Disk ][ controller card
.byte $c9,$20,$c9,$00,$c9,$03,$c9,$3c

ldax  #hello_world
jsr print

rts

sta $cfff ;turn of all other expansion ROMs
sta $c0f4 ;set bank
ldax #$c800

jsr print
rts

  
print:
	sta pptr
	stx pptr + 1
	
@print_loop:
  ldy #0
  lda (pptr),y
	beq @done_print
	jsr print_a
	inc pptr
	bne @print_loop
  inc pptr+1
  bne @print_loop ;if we ever get to $ffff, we've probably gone far enough ;-)
@done_print:
  rts


hello_world:
  .byte "hello from autostart firmware land!",13,0


