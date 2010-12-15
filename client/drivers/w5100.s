; Ethernet driver for W5100 W5100 chip 
;

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.include "../inc/common.i"

.include "w5100.i"

DEFAULT_W5100_BASE = $DF20

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

	.export w5100_init
	.export w5100_read_reg
	.export w5100_write_reg
	.import cfg_mac
	.import	cfg_ip
	.import	cfg_netmask
	.import	cfg_gateway

	.export icmp_ping
	.export icmp_echo_ip
	.export ip_init
	.export ip_process

  .import ip65_error


	.segment "IP65ZP" : zeropage
	

	
	.code

;initialize the ethernet adaptor
;inputs: none
;outputs: carry flag is set if there was an error, clear otherwise
;this implementation uses a default address for the w5100, and can be
;called as a 'generic' eth driver init function
;w5100 aware apps can use w5100_init and pass in a different
;base address
eth_init:
	ldax	#DEFAULT_W5100_BASE

;initialize the w5100 ethernet adaptor
;inputs: AX=base address for w5100 i/o 
;outputs: carry flag is set if there was an error, clear otherwise
w5100_init:
	stx	set_hi+2
	stx	set_lo+2
	stx	read_data_reg+2
	stx	write_data_reg+2
	stx	read_mode_reg+2
	stx write_mode_reg+2
	tax
	stx read_mode_reg+1
	stx write_mode_reg+1
	inx
	stx	set_hi+1
	inx
	stx	set_lo+1
	inx
	stx	read_data_reg+1
	stx	write_data_reg+1

	
	lda #$80  ;reset
	jsr	write_mode_reg
	jsr	read_mode_reg
	bne @error	;writing a byte to the MODE register with bit 7 set should reset.
				;after a reset, mode register is zero
				;therefore, if there is a real W5100 at the specified address,
				;we should be able to write a $80 and read back a $00
	lda #$03  ;set indirect + autoincrement
	jsr	write_mode_reg
	jsr	read_mode_reg
	cmp #$03
	bne @error	;make sure if we write to mode register without bit 7 set,
				;the value persists.
	ldax #$0016
	jsr	set_register_address
	ldx #$00		;start writing to reg $0016 - Interrupt Mask Register
@loop:
	lda w5100_config_data,x	
	jsr	write_data_reg
	inx
	cpx #$06
	bne @loop
	
	lda #$09
	jsr	set_lo
	ldx #$00		;start writing to reg $0009 - MAC address
	
@mac_loop:
	lda cfg_mac,x
	jsr	write_data_reg
	inx
	cpx #$06
	bne @mac_loop
	
	jsr set_ip_params
	
	;set up socket 0 for MAC RAW mode
	ldax #W5100_S0_MR
	ldy	#W5100_MODE_IP_RAW
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
	inc	$d020
	sec
	rts
	
; read one of the W5100 registers
; inputs: AX = register number to read
; outputs: A = value of nominated register
; y is overwritten
w5100_read_reg:	
	jsr	set_register_address
	jmp	read_data_reg

; write to one of the W5100 registers
; inputs: AX = register number to read
;	Y = value to write to register
; outputs: none
w5100_write_reg:
	jsr	set_register_address
	tya
	jmp	write_data_reg


set_ip_params:
	ldax #W5100_GAR0
	jsr	set_register_address
	ldx	#0
@gateway_loop:	
	lda	cfg_gateway,x
	jsr	write_data_reg
	inx
	cpx #$04
	bne	@gateway_loop
	ldx	#0	
@netmask_loop:	
	lda	cfg_netmask,x
	jsr	write_data_reg
	inx
	cpx #$04
	bne	@netmask_loop
	ldax #W5100_SIPR0
	jsr	set_register_address
	ldx	#0
@ip_loop:	
	lda	cfg_ip,x
	jsr	write_data_reg
	inx
	cpx #$04
	bne	@ip_loop
	rts
	
icmp_ping:
ip_init:
ip_process:
	rts


.rodata
eth_driver_name:
	.asciiz "WIZNET 5100"
w5100_config_data:	
  .byte $00  ;no interrupts 
  .byte $0f  ;400ms retry (default)
  .byte $a0
  .byte $08  ;# of timeouts
  .byte $55  ;4 sockets @2K each, tx/rx
  .byte $55

.segment "SELF_MODIFIED_CODE"


set_register_address:
set_hi:
	stx $FFFF	;WIZNET_ADDR_HI
set_lo:
	sta $FFFF	;WIZNET_ADDR_LO
	rts
read_data_reg:
	lda	$FFFF	;WIZNET_DATA
	rts
write_data_reg:
	sta	$FFFF	;WIZNET_DATA
	rts
read_mode_reg:
	lda	$FFFF	;WIZNET_BASE
	rts
 write_mode_reg:
 	sta	$FFFF	;WIZNET_BASE
 	rts
 .bss
 temp: .res 1
 icmp_echo_ip:
 
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
