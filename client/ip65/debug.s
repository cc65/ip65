;originally from Per Olofsson's IP65 library - http://www.paradroid.net/ip65

.include "../inc/common.i"
.include "../inc/printf.i"


	.export dbgout16
	.export dbg_dump_eth_header
	.export dbg_dump_ip_header
	.export dbg_dump_udp_header

	.export console_out
	.export console_strout


	.import eth_outp, eth_outp_len
	.import ip_outp
	.import udp_outp


	.segment "IP65ZP" : zeropage

cptr:	.res 2


	.code


dbg_dump_eth_header:
	pha
	txa
	pha
	tya
	pha

	printf "\rethernet header:\r"
	printf "len: %04x\r", eth_outp_len
	printf "dest: %04x:%04x:%04x\r", eth_outp, eth_outp + 2, eth_outp + 4
	printf "src: %04x:%04x:%04x\r", eth_outp + 6, eth_outp + 8, eth_outp + 10
	printf "type: %04x\r", eth_outp + 12

	pla
	tay
	pla
	tax
	pla
	rts


dbg_dump_ip_header:
	pha
	txa
	pha
	tya
	pha

	printf "\rip header:\r"
	printf "ver,ihl,tos: %04x\r", ip_outp
	printf "len: %04x\r", ip_outp + 2
	printf "id: %04x\r", ip_outp + 4
	printf "frag: %04x\r", ip_outp + 6
	printf "ttl: %02x\r", ip_outp + 8
	printf "proto: %02x\r", ip_outp + 9
	printf "cksum: %04x\r", ip_outp + 10
	printf "src: %04x%04x\r", ip_outp + 12, ip_outp + 14
	printf "dest: %04x%04x\r", ip_outp + 16, ip_outp + 18

	pla
	tay
	pla
	tax
	pla
	rts


dbg_dump_udp_header:
	pha
	txa
	pha
	tya
	pha

	printf "\rudp header:\r"
	printf "srcport: %04x\r", ip_outp
	printf "destport: %04x\r", ip_outp + 2
	printf "len: %04x\r", ip_outp + 4
	printf "cksum: %04x\r", ip_outp + 6

	pla
	tay
	pla
	tax
	pla
	rts


console_out	= $ffd2

console_strout:
	stax cptr

	pha
	txa
	pha
	tya
	pha
	ldy #0
:	lda (cptr),y
	beq @done
	jsr console_out
	iny
	bne :-
@done:
	pla
	tay
	pla
	tax
	pla
	rts


dbgout16:
	stax val16	
	printf "%04x", val16
	rts


	.bss

val16:	.res 2
