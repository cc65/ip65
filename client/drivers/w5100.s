; Ethernet driver for W5100 W5100 chip 
;

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.include "../inc/common.i"

.include "w5100.i"

	.export eth_init
	.export eth_rx
	.export eth_tx
	.export eth_driver_name
	.import eth_inp
	.import eth_inp_len
	.import eth_outp
	.import eth_outp_len

	.importzp eth_dest
	.importzp eth_src
	.importzp eth_type
	.importzp eth_data

	.export w5100_read_reg
	.export w5100_write_reg
	
	.import cfg_mac

  .import ip65_error


	.segment "IP65ZP" : zeropage

W5100_BASE = $DF20
W5100_ADDR_HI = W5100_BASE+1
W5100_ADDR_LO = W5100_BASE+2
W5100_DATA =    W5100_BASE+3


	
	.code

;initialize the ethernet adaptor
;inputs: none
;outputs: carry flag is set if there was an error, clear otherwise
eth_init:
	lda #$80  ;reset
	sta W5100_BASE
	lda W5100_BASE
	bne @error	;writing a byte to the MODE register with bit 7 set should reset.
				;after a reset, mode register is zero
				;therefore, if there is a real W5100 at the specified address,
				;we should be able to write a $80 and read back a $00
	lda #$03  ;set indirect + autoincrement
	sta W5100_BASE
	lda W5100_BASE
	cmp #$03
	bne @error	;make sure if we write to mode register without bit 7 set,
				;the value persists.
	lda #$00
	sta W5100_ADDR_HI
	lda #$16		
	sta W5100_ADDR_LO
	ldx #$00		;start writing to reg $0016 - Interrupt Mask Register
@loop:
	lda w5100_config_data,x
	sta W5100_DATA
	inx
	cpx #$06
	bne @loop
	
	lda #$09
	sta W5100_ADDR_LO
	ldx #$00		;start writing to reg $0009 - MAC address
@mac_loop:
	lda cfg_mac,x
	sta W5100_DATA
	inx
	cpx #$06
	bne @mac_loop
	
	;set up socket 0 for MAC RAW mode
	ldax #W5100_S0_MR
	ldy	#W5100_MODE_MAC_RAW
	jsr	w5100_write_reg
	
	;open socket 0 
	ldax #W5100_S0_CR
	ldy	#W5100_CMD_OPEN
	jsr	w5100_write_reg
	
	clc
	rts
@error:  
	sec
	rts		;

;receive a packet
;inputs: none
;outputs:
; if there was an error receiving the packet (or no packet was ready) then carry flag is set
; if packet was received correctly then carry flag is clear, 
; eth_inp contains the received packet, 
; and eth_inp_len contains the length of the packet
eth_rx:


; send a packet
;inputs:
; eth_outp: packet to send
; eth_outp_len: length of packet to send
;outputs:
; if there was an error sending the packet then carry flag is set
; otherwise carry flag is cleared
eth_tx:
	
	sec
	rts
	
; read one of the W5100 registers
; inputs: AX = register number to read
; outputs: A = value of nominated register
w5100_read_reg:	
	stx W5100_ADDR_HI
	sta W5100_ADDR_LO
	lda W5100_DATA
	rts

; write to one of the W5100 registers
; inputs: AX = register number to read
;	Y = value to write to register
; outputs: none
w5100_write_reg:	
	stx W5100_ADDR_HI
	sta W5100_ADDR_LO
	sty W5100_DATA
	rts
	
.rodata
eth_driver_name:
	.asciiz "W5100 5100"
w5100_config_data:	
  .byte $00  ;no interrupts 
  .byte $0f  ;400ms retry (default)
  .byte $a0
  .byte $08  ;# of timeouts
  .byte $55  ;4 sockets @2K each, tx/rx
  .byte $55
  
;-- LICENSE FOR w5100a.s --
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
; The Initial Developer of the Original Code is Jonno Downes (jonno@jamtronix.com)
; Portions created by the Initial Developer is Copyright (C) 2010
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
