; Ethernet driver for W5100 W5100 chip 
;

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.include "../inc/common.i"

	.export eth_init
	.export eth_rx
	.export eth_tx
	.export eth_driver_name

	.import eth_inp
	.import eth_inp_len
	.import eth_outp
	.import eth_outp_len

	
	.code

;initialize the ethernet adaptor
;inputs: none
;outputs: carry flag is set if there was an error, clear otherwise
eth_init:
	sec 	;FIX ME !
	rts
	

;receive a packet
;inputs: none
;outputs:
; if there was an error receiving the packet (or no packet was ready) then carry flag is set
; if packet was received correctly then carry flag is clear, 
; eth_inp contains the received packet, 
; and eth_inp_len contains the length of the packet
eth_rx:
	sec 	;FIX ME !
	rts
	

; send a packet
;inputs:
; eth_outp: packet to send
; eth_outp_len: length of packet to send
;outputs:
; if there was an error sending the packet then carry flag is set
; otherwise carry flag is cleared
eth_tx:
	sec 	;FIX ME !
	rts

	
.rodata
eth_driver_name:
	.asciiz "LANceGS (91C96)"

; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
; 
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
; 
; The Original Code is ip65.
; 
; The Initial Developer of the Original Code is <## TBD ##>
; Portions created by the Initial Developer is Copyright (C) 2010
; All Rights Reserved.  
; -- LICENSE END --
