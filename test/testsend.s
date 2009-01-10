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
	.import ip_create_packet
	.import ip_send

	.import ip_calc_cksum
	.import ip_inp
	.import ip_outp
	.importzp ip_cksum_ptr
	.importzp ip_header_cksum
	.importzp ip_src
	.importzp ip_dest
	.importzp ip_data
	.importzp ip_len
	.importzp ip_id
	.importzp ip_proto

	.import icmp_inp
	.import icmp_outp
	.importzp icmp_type
	.importzp icmp_code
	.importzp icmp_cksum
	.importzp icmp_data


	.zeropage

printptr:	.res 2
pptr:		.res 2


	.bss

pbtemp:		.res 1
cnt:		.res 2


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
; call ip_create_packet
; set length
; set ID
; set protocol
; set destination address
	; send ping
	jsr ip_create_packet	; create packet template
	lda #0
	sta ip_outp + ip_len	; set length
	lda #64
	sta ip_outp + ip_len + 1
	lda #$12
	sta ip_outp + ip_id	; set id
	lda #$34
	sta ip_outp + ip_id + 1
	lda #$01
	sta ip_outp + ip_proto	; set protocol
	ldx #3
:	lda pingdest,x		; set destination
	sta ip_outp + ip_dest,x
	dex
	bpl :-
	inc cnt			; increment ping counter
	bne :+
	inc cnt + 1
:
	lda #8
	sta icmp_outp + icmp_type
	lda #0
	sta icmp_outp + icmp_code
	sta icmp_outp + icmp_cksum
	sta icmp_outp + icmp_cksum + 1
	lda #$12
	sta icmp_outp + icmp_data
	lda #$34
	sta icmp_outp + icmp_data + 1
	lda cnt + 1
	sta icmp_outp + icmp_data + 2
	lda cnt
	sta icmp_outp + icmp_data + 3
	ldx #35
:	txa
	ora #$20
	sta icmp_outp + icmp_data + 4,x
	dex
	bpl :-

	ldax #icmp_outp
	stax ip_cksum_ptr
	ldax #44
	jsr ip_calc_cksum
	stax icmp_outp + icmp_cksum

	jsr ip_send
	bcc @wait
	inc $d020
@wait:
	jsr eth_rx
	bcs @wait

	lda eth_inp + 12
	cmp #8
	beq :+
	jmp @waitpacket	
:
	lda eth_inp + 13
	beq @ip			; ip
	cmp #6			; arp
	beq @arp
	jmp @waitpacket

@arp:
	ldax #arpmsg
	jsr print
	ldax eth_inp_len
	jsr printint
	ldax #bytesmsg
	jsr print

	jsr arp_process		; process arp packet

 jmp @dontprint

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
@dontprint:
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

ipmsg:
	.byte "ip PACKET RECEIVED: ",0

bytesmsg:
	.byte " BYTES", 13, 0

pingdest:
	.byte 192, 168, 0, 2
