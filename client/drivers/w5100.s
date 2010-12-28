; Ethernet driver for W5100 W5100 chip 
;

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.include "../inc/common.i"

.include "w5100.i"

DEFAULT_W5100_BASE = $DF20

;DEBUG = 1
	.export eth_init
	.export eth_rx
	.export eth_tx
	.export eth_driver_name

	.import eth_inp
	.import eth_inp_len
	.import eth_outp
	.import eth_outp_len

	.import timer_init
	.import arp_init
	.import ip_init
	.import	cfg_init
	
	.importzp eth_dest
	.importzp eth_src
	.importzp eth_type
	.importzp eth_data

	.export w5100_ip65_init
	.export w5100_read_register
	.export w5100_write_register
;	.export w5100_get_current_register
;	.export w5100_select_register
;	.export	w5100_read_next_byte
;	.export	w5100_write_next_byte	

	.import cfg_mac
	.import	cfg_ip
	.import	cfg_netmask
	.import	cfg_gateway

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
	stx	get_hi+2
	stx	get_lo+2

	stx	w5100_read_next_byte+2
	stx	w5100_write_next_byte+2
	stx	read_mode_reg+2
	stx write_mode_reg+2
	tax
	stx read_mode_reg+1
	stx write_mode_reg+1
	inx
	stx	set_hi+1
	stx	get_hi+1
	inx
	stx	set_lo+1
	stx	get_lo+1
	inx
	stx	w5100_read_next_byte+1
	stx	w5100_write_next_byte+1
	
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
	jsr	w5100_select_register
	ldx #$00		;start writing to reg $0016 - Interrupt Mask Register
@loop:
	lda w5100_config_data,x	
	jsr	w5100_write_next_byte
	inx
	cpx #$06
	bne @loop
	
	lda #$09
	jsr	set_lo
	ldx #$00		;start writing to reg $0009 - MAC address
	
@mac_loop:
	lda cfg_mac,x
	jsr	w5100_write_next_byte
	inx
	cpx #$06
	bne @mac_loop
	
	
	;set up socket 0 for MAC RAW mode , no autoinc, no ping
	lda #$11  ;set indirect - no autoincrement, no automatic ping response
	jsr	write_mode_reg


	ldax #W5100_RMSR	;rx memory size (each socket)
	ldy	#$0A			;sockets 0 & 1 4KB each, other sockets 0KB
						;if this is changed, change the mask in eth_rx as well!

	jsr	w5100_write_register

	ldax #W5100_TMSR	;rx memory size (each socket)
	ldy	#$0A			;sockets 0 & 1 4KB each, other sockets 0KB
						;if this is changed, change the mask in eth_tx as well!
	jsr	w5100_write_register

	ldax #W5100_S0_MR
	ldy	#W5100_MODE_MAC_RAW
	jsr	w5100_write_register
	
	;open socket 0 
	ldax #W5100_S0_CR
	ldy	#W5100_CMD_OPEN
	jsr	w5100_write_register
	
	clc
	rts
@error:  
	sec
	rts		;

;initialize the ip65 stack for the w5100 ethernet adaptor
;inputs: AX=base address for w5100 i/o 
;outputs: carry flag is set if there was an error, clear otherwise
;this routine can be called multiple times, with different addresses
;so a W5100  can be detected at different locations

w5100_ip65_init:
	stax  w5100_addr
  	jsr cfg_init    ;copy default values (including MAC address) to RAM
  	ldax  w5100_addr	
	jsr w5100_init		; initialize ethernet driver
  
	bcc @ok
  	lda #KPR_ERROR_DEVICE_FAILURE
  	sta ip65_error
  	rts
@ok:  
	jsr timer_init		; initialize timer
	jsr arp_init		; initialize arp
	jsr ip_init		; initialize ip, icmp, udp, and tcp
	clc
	rts


;receive a packet
;inputs: none
;outputs:
; if there was an error receiving the packet (or no packet was ready) then carry flag is set
; if packet was received correctly then carry flag is clear, 
; eth_inp contains the received packet, 
; and eth_inp_len contains the length of the packet
eth_rx:

	ldax #W5100_S0_RX_RSR0 
	jsr	w5100_read_register
	sta	eth_inp_len+1
	ldax #W5100_S0_RX_RSR1
	jsr	w5100_read_register
	sta	eth_inp_len
	bne	@got_data
	lda	eth_inp_len+1
	bne	@got_data
	sec
	rts
@got_data:

	lda #$8D	;opcode for STA
	sta next_eth_packet_byte
	ldax #eth_inp
	sta	eth_ptr_lo
	stx eth_ptr_hi
	lda #2
	sta  byte_ctr_lo
	lda	#0
	sta  byte_ctr_hi

.ifdef DEBUG
	.import print_hex
	.import	print_cr		
	lda	eth_inp_len+1
	jsr	print_hex
	lda	eth_inp_len
	jsr	print_hex
.endif

;read the 2 byte frame length
	jsr	@get_current_rx_rd
	jsr	@mask_and_adjust_rx_read

.ifdef DEBUG
	lda rx_rd_ptr+1	;DEBUG
	jsr	print_hex	;DEBUG
	lda rx_rd_ptr	;DEBUG
	jsr	print_hex	;DEBUG
.endif	
	
	ldax rx_rd_ptr
	jsr	w5100_read_register
	sta eth_inp_len+1	;high byte of frame length
.ifdef DEBUG	
	jsr	print_hex	;DEBUG
.endif	
	jsr @inc_rx_rd_ptr
	ldax rx_rd_ptr
	jsr	w5100_read_register
	sta eth_inp_len	;lo byte of frame length
.ifdef DEBUG	
	jsr	print_hex	;DEBUG
	jsr	print_cr	;DEBUG
.endif

	;now copy the rest of the frame to the eth_inp buffer
@get_next_byte:
	jsr @inc_rx_rd_ptr
	ldax rx_rd_ptr
	jsr	w5100_read_register
	jsr next_eth_packet_byte

	inc	byte_ctr_lo
	bne	:+
	inc	byte_ctr_hi
:	

	lda	byte_ctr_lo
	cmp	eth_inp_len
	bne	@get_next_byte
	lda	byte_ctr_hi
	cmp	eth_inp_len+1
	bne	@get_next_byte

.ifdef DEBUG	
;print first 40 bytes of frame	
 	ldy #0	
@print_loop:
  	tya
  	pha
  	lda eth_inp,y
	jsr	print_hex
	pla
	tay
	iny
	cpy #40
	bne	@print_loop

	jsr	print_cr	;DEBUG
.endif	
	
;update the RX RD pointer past the frame we just read	
	jsr	@get_current_rx_rd
	clc	
	lda	rx_rd_ptr
	adc eth_inp_len
	sta rx_rd_ptr
	lda	rx_rd_ptr+1
	adc eth_inp_len+1
	tay
	ldax #W5100_S0_RX_RD0
	jsr	w5100_write_register
	ldy rx_rd_ptr
	
	ldax #W5100_S0_RX_RD1
	jsr	w5100_write_register
	ldax #W5100_S0_CR
 	ldy	#W5100_CMD_RECV
	jsr	w5100_write_register

;now adjust the input length to remove the 2 byte header length
	sec
	lda	eth_inp_len
	sbc	#2
	sta	eth_inp_len
	bcs	:+
	dec	eth_inp_len
:	

	
	clc
	rts

@inc_rx_rd_ptr:
	inc	rx_rd_ptr
	bne	:+
	inc	rx_rd_ptr+1
@mask_and_adjust_rx_read:
	lda rx_rd_ptr+1
	and	#$0F
	clc
	adc	#$60
	sta rx_rd_ptr+1
:	
	rts
	
@get_current_rx_rd:
	ldax #W5100_S0_RX_RD0
	jsr	w5100_read_register	
	sta rx_rd_ptr+1
	ldax #W5100_S0_RX_RD1
	jsr	w5100_read_register
	sta rx_rd_ptr
	rts

; send a packet
;inputs:
; eth_outp: packet to send
; eth_outp_len: length of packet to send
;outputs:
; if there was an error sending the packet then carry flag is set
; otherwise carry flag is cleared
eth_tx:
	
	lda #$AD	;opcode for LDA
	sta next_eth_packet_byte
	ldax #eth_outp
	sta	eth_ptr_lo
	stx eth_ptr_hi
	lda #0
	sta  byte_ctr_lo
	sta  byte_ctr_hi
	
	jsr @get_current_tx_wr	
	jmp	@calculate_tx_wr_ptr	
@send_next_byte:
	
	jsr	next_eth_packet_byte
	tay
	ldax tx_wr_ptr
	jsr	w5100_write_register
		
	inc	byte_ctr_lo
	bne	:+
	inc	byte_ctr_hi
:	

	inc	tx_wr_ptr
	bne	:+
	inc tx_wr_ptr+1
@calculate_tx_wr_ptr:	
	lda tx_wr_ptr+1
	and	#$0F
	clc
	adc	#$40
	sta tx_wr_ptr+1
:

	lda	byte_ctr_lo
	cmp	eth_outp_len
	bne	@send_next_byte
	lda	byte_ctr_hi
	cmp	eth_outp_len+1
	bne	@send_next_byte	

;all bytes copied, now adjust the tx write ptr and SEND
	jsr @get_current_tx_wr	
	clc	
	lda	tx_wr_ptr
	adc eth_outp_len
	sta tx_wr_ptr
	lda	tx_wr_ptr+1
	adc eth_outp_len+1
	tay
	ldax #W5100_S0_TX_WR0
	jsr	w5100_write_register
	ldy tx_wr_ptr
	ldax #W5100_S0_TX_WR1
	jsr	w5100_write_register
	ldax #W5100_S0_CR
 	ldy	#W5100_CMD_SEND
 	jsr	w5100_write_register
	
	clc
	rts

@get_current_tx_wr:
	ldax #W5100_S0_TX_WR0
	jsr	w5100_read_register	
	sta tx_wr_ptr+1
	ldax #W5100_S0_TX_WR1
	jsr	w5100_read_register
	sta tx_wr_ptr
	rts

advance_eth_ptr:
	inc	eth_ptr_lo
	bne	:+
	inc	eth_ptr_hi
:	
	rts
	
	
; read one of the W5100 registers
; inputs: AX = register number to read
; outputs: A = value of nominated register
; y is overwritten
w5100_read_register:	
	jsr	w5100_select_register
	jmp	w5100_read_next_byte

; write to one of the W5100 registers
; inputs: AX = register number to write
;	Y = value to write to register
; outputs: none
w5100_write_register:
	jsr	w5100_select_register
	tya
	jmp	w5100_write_next_byte


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

;
; select one of the W5100 registers for subsequent read or write
; inputs: AX = register number to select
; outputs: none
w5100_select_register:
set_hi:
	stx $FFFF	;WIZNET_ADDR_HI
set_lo:
	sta $FFFF	;WIZNET_ADDR_LO
	rts

; return which W5100 register the next read or write will access
; inputs: none
; outputs: AX = selected register number
w5100_get_current_register:	
get_hi:
	ldx $FFFF	;WIZNET_ADDR_HI
get_lo:
	lda $FFFF	;WIZNET_ADDR_LO
	rts

; read value from previously selected W5100 register 
; inputs: none
; outputs: A = value of selected register number (and register pointer auto incremented)	
w5100_read_next_byte:
	lda	$FFFF	;WIZNET_DATA
	rts
	
; write value to previously selected W5100 register 
; inputs: A = value to write to selected register
; outputs: none (although W5100 register pointer auto incremented)	
w5100_write_next_byte:
	sta	$FFFF	;WIZNET_DATA
	rts


read_mode_reg:
	lda	$FFFF	;WIZNET_BASE
	rts
 write_mode_reg:
 	sta	$FFFF	;WIZNET_BASE
 	rts

next_eth_packet_byte:
	lda	$FFFF	;eth_packet
	jmp advance_eth_ptr
	
eth_ptr_lo=next_eth_packet_byte+1
eth_ptr_hi=next_eth_packet_byte+2

 .bss
 w5100_addr: .res 2
 byte_ctr_lo: .res 1
 byte_ctr_hi: .res 1
 
 tx_wr_ptr: .res 2
 rx_rd_ptr: .res 2
 
 
 
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
