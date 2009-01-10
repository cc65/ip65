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

	.import ip_init
	.import ip_process


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
	lda #0
	sta $d021

	jsr eth_init		; initialize ethernet driver
	ldx #0
	bcc :+

	ldax #failmsg
	jmp print

:	ldax #startmsg
	jsr print

	jsr arp_init		; initialize arp

	jsr ip_init		; initialize ip and icmp

@waitpacket:
	jsr eth_rx
	bcs @waitpacket

	lda eth_inp + 12
	cmp #8
	bne @waitpacket	

	lda eth_inp + 13
	beq @ip			; ip
	cmp #6			; arp
	bne @waitpacket

@arp:
	jsr arp_process		; process arp packet

	jmp @waitpacket

	ldax #arpmsg
	jsr print
	ldax eth_inp_len
	jsr printint
	ldax #bytesmsg
	jsr print


	ldax #eth_inp
	stax pptr

	ldy #petscii_ltred	; dest addr
	lda #6
	jsr printbytes

	ldy #petscii_ltgreen	; src addr
	lda #6
	jsr printbytes

	ldy #petscii_ltgray	; type
	lda #2
	jsr printbytes

	lda #13
	jsr $ffd2

	ldy #petscii_yellow	; hw, proto, hwlen, protolen, op
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

	lda #petscii_ltblue
	jsr $ffd2

@wp:
	jmp @waitpacket

@ip:
	lda ip_inp + ip_proto
	cmp #1
	bne @wp

	ldax #ipmsg
	jsr print
	ldax eth_inp_len
	jsr printint
	ldax #bytesmsg
	jsr print

	lda #petscii_white
	jsr $ffd2
	lda ip_inp + ip_proto
	jsr printhex

	ldax #ip_inp + ip_src
	stax pptr
	ldy #petscii_ltgreen
	lda #4
	jsr printbytes

	ldax #ip_inp + ip_dest
	stax pptr
	ldy #petscii_ltred
	lda #4
	jsr printbytes

	lda #petscii_ltblue
	jsr $ffd2
	lda #13
	jsr $ffd2
;	jsr $ffd2

	jsr ip_process			; handle packet

	jmp @waitpacket
; ip packets start at ethernet packet + 14
ip_inp		= eth_inp + 14

; ip packet offsets
ip_proto	= 9
ip_src		= 12
ip_dest		= 16



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
	.byte "arp PACKET RECEIVED: ", 0

ipmsg:
	.byte "ip PACKET RECEIVED: ",0

bytesmsg:
	.byte " BYTES", 13, 0
