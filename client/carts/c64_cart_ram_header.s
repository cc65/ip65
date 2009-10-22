.segment "IP65ZP" : zeropage

; pointers for copying
copy_src:	.res 2			; source pointer
copy_dest:	.res 2			; destination pointer
end:		.res 1

.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

	.word basicstub		; load address
.include "../inc/common.i"

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

  ;turn off BASIC
  lda $01
  and #$FE  ;mask out bit 0
  sta $01
  
  ;now relocate the cart
  
  ldax #cart_data
  stax copy_src
  ldax #$8000
  stax copy_dest
  ldax #$4000
  jsr copymem
  
  jmp ($8002) ;warm start vector
 
;copy memory
;inputs:
; copy_src is address of buffer to copy from
; copy_dest is address of buffer to copy to
; AX = number of bytes to copy
;outputs: none
copymem:
	sta end
	ldy #0

	cpx #0
	beq @tail

:	lda (copy_src),y
	sta (copy_dest),y
	iny
	bne :-
  inc copy_src+1    ;next page
  inc copy_dest+1  ;next page
	dex
	bne :-

@tail:
	lda end
	beq @done

:	lda (copy_src),y
	sta (copy_dest),y
	iny
	cpy end
	bne :-

@done:
	rts
 
;this is where the cart data will be appended to: 
 cart_data:
  
;-- LICENSE FOR c64_cart_ram_header.s --
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
; The Original Code is netboot65.
; 
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
