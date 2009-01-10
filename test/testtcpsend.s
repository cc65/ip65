.include "../inc/common.i"

	.import dbgout16


	.import ip65_init
	.import ip65_process

	.import tcp_connect
	.import tcp_callback
	.import tcp_send
  .import tcp_close

  .import dhcp_init
	.import tcp_inp
	.import tcp_outp

	.importzp tcp_data
	.importzp tcp_len
	.importzp tcp_src_port
	.importzp tcp_dest_port

	.import tcp_send_dest
	.import tcp_send_src_port
	.import tcp_send_dest_port
	.import tcp_send_len

	.importzp ip_src
	.import ip_inp


	.zeropage

pptr:		.res 2


	.bss

cnt:		.res 1
replyaddr:	.res 4
replyport:	.res 2
idle		= 1
recv		= 2
resend		= 3


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
	jsr ip65_init
	bcc :+

	ldax #failmsg
	jmp print
:
  jsr dhcp_init

	bcc :+

	ldax #failmsg
	jmp print

:
ldax #startmsg
	jsr print

	jsr ip65_process


send:
	ldx #3
:	lda serverip,x			; set destination
	sta tcp_send_dest,x
	dex
	bpl :-

	ldax #3172			; set source port
	stax tcp_send_src_port

	ldax #3172			; set dest port
	stax tcp_send_dest_port

;  ldax #tcp_in
;	stax tcp_callback
  
  jsr tcp_connect
@fixme:
  jmp @fixme
  
	
  bcc :+
  ldax #tcpfailmsg
	jsr print
	rts
:

	ldax #tcpsendend - tcpsendmsg	; set length
	stax tcp_send_len

	ldax #tcpsendmsg
	jsr tcp_send



rts


udp_in:

	rts


print:
	sta pptr
	stx pptr + 1
	ldy #0
:	lda (pptr),y
	beq :+
	jsr $ffd2
	iny
	bne :-
:	rts


	.rodata

startmsg:
	.byte "INITIATING TCP CONNECTION", 13, 0

failmsg:
	.byte  "RR-NET INIT FAILED", 13, 0

tcpfailmsg:
	.byte "TCP CONNECT FAILED", 13, 0

tcpsendmsg:
	.byte "Hello, world!", 13, 10
tcpsendend:

serverip:
	.byte 10, 5, 1, 1
