.include "../inc/common.i"
.include "../inc/petscii.i"


	.import timer_init
	.import timer_read
	.import timer_timeout


	.zeropage

printptr:	.res 2


	.bss

time:		.res 2


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
	jsr timer_init

	lda #petscii_clear
	jsr $ffd2

@print:
	lda #petscii_home
	jsr $ffd2

	jsr timer_read
	jsr printint

	lda $c6
	beq @print

	dec $c6
	jsr timer_read
	clc
	adc #<1000
	sta time
	txa
	adc #>1000
	sta time + 1

:	ldax time
	jsr timer_timeout
	bcs :-
	bcc @print


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

