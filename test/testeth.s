.include "../inc/common.i"
.include "../inc/petscii.i"


	.import eth_init
	.import eth_init
	.import eth_rx
	.import eth_tx
	.import eth_inp
	.import eth_inp_len


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
	jsr eth_init
	ldx #0
	bcc :+

	ldax #failmsg
	jmp print

:	ldax #startmsg
	jsr print

@waitpacket:
	jsr eth_rx
	bcs @waitpacket

;	lda eth_inp + 12
;	cmp #8
;	bne @waitpacket	

	ldax #packetmsg
	jsr print
	ldax eth_inp_len
	jsr printint
	ldax #bytesmsg
	jsr print

	ldax #eth_inp
	stax pptr

	lda #petscii_ltred		; dest addr
	jsr $ffd2
	lda #6
	jsr printbytes
	lda #6
	jsr addpptr

	lda #petscii_ltgreen		; src addr
	jsr $ffd2
	lda #6
	jsr printbytes
	lda #6
	jsr addpptr

	lda #petscii_ltgray		; type
	jsr $ffd2
	lda #2
	jsr printbytes

	lda #13
	jsr $ffd2

	ldy #0
	lda (pptr),y
	cmp #$08
	bne @done

	iny
	lda (pptr),y
	beq @ip
	cmp #6
	beq @arp
	bne @done

@ip:
	lda #2
	jsr addpptr

	lda #petscii_white
	jsr $ffd2
	lda #10
	jsr printbytes
	lda #10
	jsr addpptr
	lda #13
	jsr $ffd2

	lda #10
	jsr printbytes
	lda #10
	jsr addpptr
	lda #13
	jsr $ffd2

	jmp @done

@arp:
	lda #2
	jsr addpptr

	lda #petscii_yellow
	jsr $ffd2
	lda #8
	jsr printbytes
	lda #13
	jsr $ffd2

@done:
	lda #petscii_ltblue
	jsr $ffd2
	lda #13
	jsr $ffd2

	jmp @waitpacket


addpptr:
	clc
	adc pptr
	sta pptr
	bcc :+
	inc pptr+1
:	rts


printbytes:
	sta pbtemp
	ldy #0
:	lda (pptr),y
	jsr printhex
	iny
	cpy pbtemp
	bne :-
	rts


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

macaddr:
	.byte $0c, $64, "PO", $74, $04

startmsg:
	.byte 14, "rr-nET INITIALIZED", 13, 0

failmsg:
	.byte 14, "rr-nET INIT FAILED", 13, 0

packetmsg:
	.byte "PACKET RECEIVED: ",0

bytesmsg:
	.byte " BYTES", 13, 0
