; Common ethernet driver code (independant of host computer or ethernet chipset)

.include "../inc/common.i"

	.export eth_set_broadcast_dest
	.export eth_set_my_mac_src
	.export eth_set_proto

	.exportzp eth_proto_ip
	.exportzp eth_proto_arp

	.import eth_outp

	.import cfg_mac


; ethernet packet offsets
eth_dest	= 0		; offset of destination address in ethernet packet
eth_src		= 6		; offset of source address in ethernet packet
eth_type	= 12		; offset of packet type in ethernet packet
eth_data	= 14		; offset of packet data in ethernet packet

; protocols

eth_proto_ip	= 0
eth_proto_arp	= 6


	.code
;set the destination address in the packet under construction to be the ethernet
;broadcast address (FF:FF:FF:FF:FF:FF)
;inputs:
; eth_outp: buffer in which outbound ethernet packet is being constructed
;outputs: none
eth_set_broadcast_dest:
	ldx #5
	lda #$ff
:	sta eth_outp,x
	dex
	bpl :-
	rts

;set the source address in the packet under construction to be local mac address
;inputs:
; eth_outp: buffer in which outbound ethernet packet is being constructed
;outputs: none
eth_set_my_mac_src:
	ldx #5
:	lda cfg_mac,x
	sta eth_outp + 6,x
	dex
	bpl :-
	rts

;set the 'protocol' field in the packet under construction
;inputs: 
;   A = protocol number (per 'eth_proto_*' constants)
;outputs: none
eth_set_proto:
	sta eth_outp + eth_type + 1
	lda #8
	sta eth_outp + eth_type
	rts
