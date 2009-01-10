.include "../inc/common.i"
.include "../inc/petscii.i"


	.import ip_calc_cksum
	.importzp ip_cksum_ptr


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
	jsr printpacket

calccksum:
	ldax #0
	stax ip_outp + ip_header_cksum	; null any garbage checksum

	ldax #ip_outp
	stax ip_cksum_ptr
	ldax #20
	jsr ip_calc_cksum
	stax ip_outp + ip_header_cksum

icmp_outp	= ip_outp + 20
icmp_cksum	= 2

	ldax #0
	stax icmp_outp + icmp_cksum
	ldax #icmp_outp
	stax ip_cksum_ptr
	ldax #40
	jsr ip_calc_cksum
	stax icmp_outp + icmp_cksum

	jsr printpacket

	rts


printpacket:
	ldx #0
:	lda ip_outp,x
	jsr printhex
	txa
	and #7
	tay
	lda sep,y
	jsr $ffd2
	inx
	cpx #60
	bne :-
	lda #13
	jsr $ffd2
	jsr $ffd2
	rts


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
	tay
	lda hexdigit,y
	jsr $ffd2
	pla
	and #$0f
	tay
	lda hexdigit,y
	jsr $ffd2
	rts


	.data

hexdigit:
	.byte "0123456789ABCDEF"

ip_header_cksum = 10
ip_data		= 20

yip_outp:
	.byte $45, $00, $00, $3c, $65, $f7, $40, $00
	.byte $f3, $01, $a9, $21, $82, $f1, $35, $0c
	.byte $c0, $a8, $00, $02, $00, $00, $36, $5c
	.byte $04, $00, $1b, $00, $61, $62, $63, $64
	.byte $65, $66, $67, $68, $69, $6a, $6b, $6c
	.byte $6d, $6e, $6f, $70, $71, $72, $73, $74
	.byte $75, $76, $77, $61, $62, $63, $64, $65
	.byte $66, $67, $68, $69

sep:
	.byte 32, 32, 32, 32, 32, 32, 32, 13

xip_outp:
	.byte $45, $00, $00, $3c, $bf, $c9, $00, $00
	.byte $80, $01, $02, $50, $c0, $a8, $00, $02
	.byte $82, $f1, $35, $0c, $08, $00, $2e, $5c
	.byte $04, $00, $1b, $00, $61, $62, $63, $64
	.byte $65, $66, $67, $68, $69, $6a, $6b, $6c
	.byte $6d, $6e, $6f, $70, $71, $72, $73, $74
	.byte $75, $76, $77, $61, $62, $63, $64, $65
	.byte $66, $67, $68, $69

ip_outp:
	.byte $45, $00, $00, $3c, $f4, $4d, $00, $00
	.byte $80, $01, $c4, $e0, $c0, $a8, $00, $40
	.byte $c0, $a8, $00, $02, $00, $00, $03, $5b
	.byte $04, $00, $4e, $00, $61, $62, $63, $64
	.byte $65, $66, $67, $68, $69, $6a, $6b, $6c
	.byte $6d, $6e, $6f, $70, $71, $72, $73, $74
	.byte $75, $76, $77, $61, $62, $63, $64, $65
	.byte $66, $67, $68, $69

zip_outp:
	.byte $45, $00, $00, $40, $12, $34, $40, $00
	.byte $40, $01, $b7, $b6, $82, $f1, $35, $b3
	.byte $82, $f1, $35, $3d, $08, $00, $af, $ed
	.byte $12, $34, $00, $97, $20, $21, $22, $23
	.byte $24, $25, $26, $27, $28, $29, $2a, $2b
	.byte $2c, $2d, $2e, $2f, $30, $31, $32, $33
	.byte $34, $35, $36, $37, $38, $39, $3a, $3b
	.byte $3c, $3d, $3e, $3f, $20, $21, $22, $23
	.byte $2d, $c9, $7f, $c1
