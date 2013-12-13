.include "../inc/common.i"

	.export console_printf


	.import console_out
	.import console_strout


	.segment "IP65ZP" : zeropage

strptr:		.res 2
argptr:		.res 2
valptr:		.res 2


	.bss

ysave:		.res 1
arg:		.res 1
fieldwidth:	.res 1
fieldwcnt:	.res 1
leadzero:	.res 1
argtemp:	.res 1
int:		.res 2
num:		.res 5
ext:		.res 2


	.code

;print a string to console, with (some) standard printf % codes converted
;inputs: AX = pointer to 'argument list' 
; first word in argument list is the string to be printed
; subsequent words in argument list are interpolated in to the string as
; it is displayed. (argument list is automagically created by the 'printf' macro
; defined in inc/printf.i)
;outputs: none
;supported % codes:
;   %s: string (argument interpreted as pointer to null terminated string)
;   %d: decimal number (arguement interpreted as 16 bit number)
;   %x: hex number (arguement interpreted as 16 bit number)
;   %c: char (arguement interpreted as pointer to single ASCII char)
;"field width" modifiers are also supported, e.g "%02x" to print 2 hex digits
console_printf:
	stax argptr
	ldy #0
	lda (argptr),y
	sta strptr
	iny
	lda (argptr),y
	sta strptr + 1
	iny
	sty arg

	ldy #0
@nextchar:
	lda (strptr),y
	bne :+
	rts
:
	cmp #'%'
	beq @printarg

	cmp #'\'
	beq @printescape

	jsr console_out

@next:
	iny
	bne @nextchar

	inc strptr + 1
	jmp @nextchar

@printescape:
	iny
	bne :+
	inc strptr + 1
:	lda (strptr),y
	ldx #esc_count - 1
:	cmp esc_code,x
	beq @escmatch
	dex
	bpl :-
	bmi @next
@escmatch:
	lda esc_char,x
	jsr console_out
	jmp @next

@printarg:
	lda #0
	sta fieldwidth
	sta leadzero
	lda #$ff
	sta fieldwcnt
@argnext:
	iny
	bne :+
	inc strptr + 1
:
	tya
	pha

	lda (strptr),y

	cmp #'0'		; check for field width
	bcc @notdigit
	cmp #'9'+1
	bcs @notdigit
	and #$0f
	bne :+			; check for leading 0
	inc fieldwcnt
	bne :+
	lda #$80
	sta leadzero
	pla
	tay
	jmp @argnext
:
	pha			; multiply old value by 10
	asl fieldwidth
	lda fieldwidth
	asl
	asl
	clc
	adc fieldwidth
	sta fieldwidth
	pla
	clc			; add new value
	adc fieldwidth
	sta fieldwidth
	pla
	tay
	jmp @argnext

@notdigit:
	cmp #'s'
	beq @argstr

	cmp #'d'
	beq @argint

	cmp #'x'
	beq @arghex

	cmp #'c'
	beq @argchar

@argdone:
	pla
	tay
	jmp @next

@argstr:
	jsr @argax
	jsr console_strout

	jmp @argdone

@argint:
	jsr @argax
	stax valptr
	jsr @valax
	jsr printint

	jmp @argdone

@arghex:
	jsr @argax
	stax valptr
	jsr @valax
	jsr printhex

	jmp @argdone

@argchar:
	jsr @argax
	stax valptr
	ldy #0
	lda (valptr),y
	jsr console_out

	jmp @argdone

@argax:
	ldy arg
	lda (argptr),y
	pha
	iny
	lda (argptr),y
	tax
	iny
	sty arg
	pla
	rts

@valax:
	ldy #0
	lda (valptr),y
	pha
	iny
	lda (valptr),y
	tax
	pla
	rts

@printx:
	txa
	lsr
	lsr
	lsr
	lsr
	tay
	lda hex2asc,y
	jsr console_out
	txa
	and #$0f
	tay
	lda hex2asc,y
	jmp console_out


; print 16-bit hexadecimal number
printhex:
	tay
	and #$0f
	sta num + 3
	tya
	lsr
	lsr
	lsr
	lsr
	sta num + 2

	txa
	and #$0f
	sta num + 1
	txa
	lsr
	lsr
	lsr
	lsr
	sta num

	lda #4
	sec
	sbc fieldwidth
	tax
	bpl :+
	jsr printlong
:
	cpx #4
	beq @nowidth

@printlead:
	lda num,x
	bne @printrest
	lda #' '
	bit leadzero
	bpl :+
	lda #'0'
:	jsr console_out
	inx
	cpx #3
	bne @printlead

@nowidth:
	ldx #0
:	lda num,x
	bne @printrest
	inx
	cpx #4
	bne :-
	lda #'0'
	jsr console_out
	rts

@printrest:
	lda num,x
	tay
	lda hex2asc,y
	jsr console_out
	inx
	cpx #4
	bne @printrest
	rts


printlong:
	lda #' '
	bit leadzero
	bpl :+
	lda #'0'
:	jsr console_out
	inx
	bne :-
	rts


; print a 16-bit integer
printint:
	stax int

	ldx #4
@next:
	lda #0
	sta num,x
	jsr div10
	lda ext
	sta num,x
	dex
	bpl @next

	lda fieldwidth
	beq @nowidth
	lda #5
	sec
	sbc fieldwidth
	tax
	bpl :+
	jsr printlong
:
@printlead:
	lda num,x
	bne @print

	lda #' '
	bit leadzero
	bpl :+
	lda #'0'
:	jsr console_out
	inx
	cpx #5
	bne @printlead
	beq @printzero

@nowidth:
	inx
	cpx #5
	beq @printzero
	lda num,x
	beq @nowidth

@print:
	clc
	adc #'0'
	jsr console_out
	inx
	cpx #5
	beq @done
@printall:
	lda num,x
	jmp @print

@done:
	rts

@printzero:
	lda #'0'
	jmp console_out


; 16/16-bit division, from the fridge
; int/aux -> int, remainder in ext
div10:
	lda #0
	sta ext+1
	ldy #$10
@dloop:
	asl int
	rol int+1
	rol
	rol ext+1
	pha
	cmp #10
	lda ext+1
	sbc #0		; is this a nop?
	bcc @div2
	sta ext+1
	pla
	sbc #10
	pha
	inc int
@div2:
	pla
	dey
	bne @dloop
	sta ext
	rts


	.rodata

msg_unimplemented:
	.byte "<unimplemented>",0

hex2asc:
	.byte "0123456789abcdef"

esc_code:
	.byte "eabfnrt", '\'
esc_count	= * - esc_code
esc_char:
	.byte 27, 7, 8, 12, 10, 13, 9, '\'



;-- LICENSE FOR printf.s --
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
; The Initial Developer of the Original Code is Per Olofsson,
; MagerValp@gmail.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Per Olofsson. All Rights Reserved.  
; -- LICENSE END --
