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





;-- LICENSE FOR c700_rom.s --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
; 
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
; 
; The Original Code is ip65.
; 
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
