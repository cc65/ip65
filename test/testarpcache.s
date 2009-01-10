.include "../inc/common.i"
.include "../inc/petscii.i"


	.import ip65_init
	.import ip65_process

	.import ip65_ctr
	.import ip65_ctr_arp
	.import ip65_ctr_ip

	.import arp_cache


	.zeropage

printptr:	.res 2
pptr:		.res 2


	.bss

pbtemp:		.res 1
cnt:		.res 1


	.segment "STARTUP"

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


	.code

init:
	lda #0
	sta $d021

	jsr ip65_init
	ldx #0
	bcc :+

	ldax #failmsg
	jmp print

:	ldax #startmsg
	jsr print

main:
	lda ip65_ctr_arp
	pha
	lda ip65_ctr_ip
	pha
	jsr ip65_process
	pla
	cmp ip65_ctr_arp
	beq :+
	jsr printarp
:	pla
	cmp ip65_ctr_ip
	beq :+
	jsr printip
:	jmp main


printarp:
	ldax #arp_cache
	stax pptr

	lda #petscii_home
	jsr $ffd2
	lda #petscii_down
	jsr $ffd2

	lda #8
	sta cnt

@print:
	ldy #petscii_ltgray
	lda #6
	jsr printbytes

	lda #' '
	jsr $ffd2

	ldy #petscii_gray
	lda #4
	jsr printbytes

	lda #13
	jsr $ffd2

	dec cnt
	bne @print

	rts


printip:
	lda #petscii_home
	jsr $ffd2
	ldx #10
	lda #petscii_down
:	jsr $ffd2
	dex
	bne :-

	lda #petscii_white
	jsr $ffd2

	lda ip65_ctr_ip
	jsr printhex

	ldax ippktmsg
	jsr print

	rts


printbytes:
	sta pbtemp
	tya
	jsr $ffd2
	ldy #0
:	lda (pptr),y
	jsr printhex
	lda #' '
	jsr $ffd2
	iny
	cpy pbtemp
	bne :-

	lda pbtemp
	clc
	adc pptr
	sta pptr
	bcc :+
	inc pptr+1
:	rts


print:
	sta printptr
	stx printptr + 1
	ldy #0
:	lda (printptr),y
	beq :+
	jsr $ffd2
	iny
	bne :-
:	rts


printint:
	pha
	txa
	jsr printhex
	pla
printhex:
	pha
	lsr
	lsr
	lsr
	lsr
	tax
	lda hexdigit,x
	jsr $ffd2
	pla
	and #$0f
	tax
	lda hexdigit,x
	jsr $ffd2
	rts


	.data

hexdigit:
	.byte "0123456789ABCDEF"

startmsg:
	.byte petscii_clear, petscii_lower, "arp CACHE:", 13, 0

failmsg:
	.byte petscii_lower, "rr-nET INIT FAILED", 13, 0

ippktmsg:
	.byte petscii_ltgray, " ip PACKETS RECEIVED",0

bytesmsg:
	.byte " BYTES", 13, 0

pingdest:
	.byte 130, 241, 53, 61
