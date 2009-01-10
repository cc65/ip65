.include "../inc/common.i"
.include "../inc/petscii.i"


	.import eth_init
	.import eth_init
	.import eth_rx
	.import eth_tx
	.import eth_inp
	.import eth_inp_len

	.import arp_init
	.import arp_lookup
	.import arp_process


	.zeropage

printptr:	.res 2
pptr:		.res 2


	.bss

pbtemp:		.res 1


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
	jsr eth_init		; initialize ethernet driver
	ldx #0
	bcc :+

	ldax #failmsg
	jmp print

:	ldax #startmsg
	jsr print

	jsr arp_init		; initialize arp

@waitpacket:
	jsr eth_rx
	bcs @waitpacket

	lda eth_inp + 12
	cmp #8
	bne @waitpacket	

	lda eth_inp + 13
	cmp #6			; arp
	bne @waitpacket

	ldax #arpmsg
	jsr print
	ldax eth_inp_len
	jsr printint
	ldax #bytesmsg
	jsr print

	jsr arp_process		; process arp packet

	ldax #eth_inp
	stax pptr

	ldy #petscii_ltred		; dest addr
	lda #6
	jsr printbytes

	ldy #petscii_ltgreen		; src addr
	lda #6
	jsr printbytes

	ldy #petscii_ltgray		; type
	lda #2
	jsr printbytes

	lda #13
	jsr $ffd2

@arp:
	ldy #petscii_yellow		; hw, proto, hwlen, protolen, op
	lda #8
	jsr printbytes
	lda #13
	jsr $ffd2

	ldy #petscii_cyan
	lda #10
	jsr printbytes
	lda #13
	jsr $ffd2

	ldy #petscii_white
	lda #10
	jsr printbytes
	lda #13
	jsr $ffd2

@done:
	lda #petscii_ltblue
	jsr $ffd2
	lda #13
	jsr $ffd2

	jmp @waitpacket


printbytes:
	sta pbtemp
	tya
	jsr $ffd2
	ldy #0
:	lda (pptr),y
	jsr printhex
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
	.byte 14, "rr-nET INITIALIZED", 13, 0

failmsg:
	.byte 14, "rr-nET INIT FAILED", 13, 0

arpmsg:
	.byte "arp PACKET RECEIVED: ",0

bytesmsg:
	.byte " BYTES", 13, 0
