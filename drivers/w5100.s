; Ethernet driver for W5100 W5100 chip 
;

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.include "../inc/common.i"

.include "w5100.i"

WIZNET_BASE=$DE04

WIZNET_MODE_REG = WIZNET_BASE
WIZNET_ADDR_HI = WIZNET_BASE+1
WIZNET_ADDR_LO = WIZNET_BASE+2
WIZNET_DATA_REG = WIZNET_BASE+3


;DEBUG = 1
	.export eth_init
	.export eth_rx
	.export eth_tx
	.export eth_driver_name
	.export eth_driver_io_base
	.import eth_inp
	.import eth_inp_len
	.import eth_outp
	.import eth_outp_len

	.import timer_init
	.import timer_read
	
	.import arp_init
	.import ip_init
	.import	cfg_init
	
	.importzp eth_dest
	.importzp eth_src
	.importzp eth_type
	.importzp eth_data
	.importzp copy_src
	.importzp copy_dest

	.export w5100_ip65_init
	.export w5100_read_register
	.export w5100_select_register

	.export w5100_write_register
	.export w5100_set_ip_config
	.export tcp_connect
	.export tcp_connect_ip
	.export tcp_callback
	.export tcp_send_data_len
	.export tcp_send_string
	.export tcp_send
	.export tcp_send_keep_alive
	.export	tcp_close
	.export tcp_state

	.export tcp_connect_remote_port
	.export tcp_remote_ip
	.export tcp_listen
	
	.export tcp_inbound_data_ptr
	.export tcp_inbound_data_length

	.import cfg_mac
	.import	cfg_ip
	.import	cfg_netmask
	.import	cfg_gateway

	.import ip65_error
	.import ip65_process
	.import check_for_abort_key

	
	.code

;initialize the ethernet adaptor
;inputs: none
;outputs: carry flag is set if there was an error, clear otherwise
;this implementation uses a default address for the w5100, and can be
;called as a 'generic' eth driver init function
eth_init:
  	lda $de01
	ora #1			;turn on clockport
	sta $de01
  
	
	lda #$80  ;reset
	sta WIZNET_MODE_REG
	lda WIZNET_MODE_REG
	bne @error	;writing a byte to the MODE register with bit 7 set should reset.
				;after a reset, mode register is zero
				;therefore, if there is a real W5100 at the specified address,
				;we should be able to write a $80 and read back a $00
	lda #$13  ;set indirect mode, with autoinc, no auto PING
	sta WIZNET_MODE_REG
	lda WIZNET_MODE_REG
	cmp #$13
	bne @error	;make sure if we write to mode register without bit 7 set,
				;the value persists.
	lda #$00
	sta	WIZNET_ADDR_HI
	lda #$16
	sta	WIZNET_ADDR_LO
	
	ldx #$00		;start writing to reg $0016 - Interrupt Mask Register
@loop:
	lda w5100_config_data,x	
	sta WIZNET_DATA_REG
	inx
	cpx #$06
	bne @loop
	
	lda #$09
	sta	WIZNET_ADDR_LO
	ldx #$00		;start writing to reg $0009 - MAC address
	
@mac_loop:
	lda cfg_mac,x
	sta WIZNET_DATA_REG
	inx
	cpx #$06
	bne @mac_loop
	
	;set up socket 0 for MAC RAW mode 

	ldax #W5100_RMSR	;rx memory size (each socket)
	stx	WIZNET_ADDR_HI
	sta	WIZNET_ADDR_LO

	lda	#$0A			;sockets 0 & 1 4KB each, other sockets 0KB
						;if this is changed, change the mask in eth_rx as well!

	sta WIZNET_DATA_REG

	ldax #W5100_TMSR	;rx memory size (each socket)
	stx	WIZNET_ADDR_HI
	sta	WIZNET_ADDR_LO

	lda	#$0A			;sockets 0 & 1 4KB each, other sockets 0KB
						;if this is changed, change the mask in eth_tx as well!
	sta WIZNET_DATA_REG

	ldax #W5100_S0_MR
	stx	WIZNET_ADDR_HI
	sta	WIZNET_ADDR_LO
	lda	#W5100_MODE_MAC_RAW
	sta WIZNET_DATA_REG
	
	;open socket 0 

	
	jsr	w5100_write_register
	ldax #W5100_S0_CR
	stx	WIZNET_ADDR_HI
	sta	WIZNET_ADDR_LO
	lda	#W5100_CMD_OPEN
	sta WIZNET_DATA_REG

	lda #tcp_cxn_state_closed
	sta tcp_state
	
	clc
	rts
@error:  
	sec
	rts		;

;initialize the ip65 stack for the w5100 ethernet adaptor
;inputs: none
;outputs: carry flag is set if there was an error, clear otherwise

w5100_ip65_init:
  	jsr cfg_init    ;copy default values (including MAC address) to RAM
	jsr eth_init
  
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

	;eth_rx will get called in the main polling loop
	;we shoe horn a check for data on the TCP socket here
	;if we do get TCP data, we will call the TCP callback routine
	;but we hide all of this from the ip65 stack proper.
	lda tcp_state	
	beq	@no_tcp

	jsr	tcp_rx
	bcc @no_tcp	;if we didn't get any TCP traffic, go check for a raw ethernet packet
		;eth_inp and eth_inp_len are not valid, so leave carry flag set to indicate no ethernet frame data 
	rts
	
@no_tcp:	

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
	stax copy_dest
	
	lda #2
	sta  byte_ctr_lo
	lda	#0
	sta  byte_ctr_hi

;read the 2 byte frame length
	jsr	@get_current_rx_rd
	jsr	@mask_and_adjust_rx_read

	
	ldax rx_rd_ptr
	jsr	w5100_read_register
	sta eth_inp_len+1	;high byte of frame length
	jsr @inc_rx_rd_ptr
	ldax rx_rd_ptr
	jsr	w5100_read_register
	sta eth_inp_len	;lo byte of frame length

	;now copy the rest of the frame to the eth_inp buffer
	;we keep our own copy of RX_RD_PTR in sync, rather than read WIZNET_ADDR registers
	;because of issue where reads to WIZNET_ADDR can cause the autoinc ptr to advance erroneously
	;when WizNet cart used in a cartridge expander
	
	ldy	#0
@get_next_byte:
	inc	rx_rd_ptr
	bne	:+
	inc	rx_rd_ptr+1
	lda rx_rd_ptr+1
	and	#$0F
	clc
	adc	#$60
	sta rx_rd_ptr+1
	sta WIZNET_ADDR_HI
:	
	lda WIZNET_DATA_REG
	sta (copy_dest),y
	iny
	bne	:+
	inc	copy_dest+1
:	
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
	lda WIZNET_DATA_REG
	rts

; write to one of the W5100 registers
; inputs: AX = register number to write
;	Y = value to write to register
; outputs: none
w5100_write_register:
	jsr	w5100_select_register
	tya
	sta WIZNET_DATA_REG
	rts




;listen for an inbound tcp connection
;this is a 'blocking' call, i.e. it will not return until a connection has been made
;inputs:
; AX: destination port (2 bytes)
; tcp_callback: vector to call when data arrives on this connection
;outputs:
;   carry flag is set if an error occured, clear otherwise
tcp_listen:

	stax  tcp_local_port
	jsr	setup_tcp_socket
	ldax #W5100_S1_CR
	ldy	#W5100_CMD_LISTEN
	jsr	w5100_write_register

	;now wait for the status to change to 'established'
@listen_loop:
;	inc $d020
	jsr	ip65_process
	jsr check_for_abort_key
	bcc @no_abort
  	lda #KPR_ERROR_ABORTED_BY_USER
  	sta	ip65_error
  	sec
  	rts
@no_abort:
	ldax #W5100_S1_SR
	jsr w5100_read_register
	cmp #W5100_STATUS_SOCK_ESTABLISHED
	bne	@listen_loop

	lda #tcp_cxn_state_established
	sta tcp_state

	;copy the remote IP address & port number
	ldax #W5100_S1_DIPR0
	jsr	w5100_select_register
	ldx	#0
@ip_loop:	
	lda WIZNET_DATA_REG
	sta	tcp_remote_ip,x
	inx
	cpx #$04
	bne	@ip_loop
	
	ldax #W5100_S1_DPORT0
	jsr	w5100_select_register
	lda WIZNET_DATA_REG
	sta tcp_connect_remote_port+1
	lda WIZNET_DATA_REG
	sta tcp_connect_remote_port
	
	clc
	rts


;make outbound tcp connection
;inputs:
; tcp_connect_ip:  destination ip address (4 bytes)
; AX: destination port (2 bytes)
; tcp_callback: vector to call when data arrives on this connection
;outputs:
;   carry flag is set if an error occured, clear otherwise
tcp_connect:
	stax tcp_remote_port
	jsr	timer_read	;get a pseudo random value
	sta tcp_local_port+1
	inc tcp_local_port
	

	jsr	setup_tcp_socket
		

	;set the destination IP address
	ldax #W5100_S1_DIPR0
	jsr	w5100_select_register
	ldx	#0
@remote_ip_loop:
	lda	tcp_connect_ip,x
	sta WIZNET_DATA_REG
	inx
	cpx #$04
	bne	@remote_ip_loop
	ldx	#0	

;W5100 register address is now W5100_S1_DPORT0, so set the destination port
	lda	tcp_remote_port+1
	sta WIZNET_DATA_REG
	lda	tcp_remote_port
	sta WIZNET_DATA_REG

	ldax #W5100_S1_CR
	ldy	#W5100_CMD_CONNECT
	jsr	w5100_write_register

	;now wait for the status to change to 'established'
@connect_loop:
	ldax #W5100_S1_SR
	jsr w5100_read_register
	cmp #W5100_STATUS_SOCK_CLOSED
	beq	@error
	cmp #W5100_STATUS_SOCK_ESTABLISHED
	beq	@ok

	jsr check_for_abort_key
	bcc @connect_loop
  	lda #KPR_ERROR_ABORTED_BY_USER
  	jmp @set_error_and_exit

@ok:
	lda #tcp_cxn_state_established
	sta tcp_state

	clc
	rts
@error:
  	lda #KPR_ERROR_CONNECTION_CLOSED
@set_error_and_exit:
  	sta ip65_error
	sec
	rts

;send a string over the current tcp connection
;inputs:
;   tcp connection should already be opened
;   AX: pointer to buffer - data up to (but not including)
; the first nul byte will be sent. max of 255 bytes will be sent.
;outputs:
;   carry flag is set if an error occured, clear otherwise
tcp_send_string:
  stax tcp_send_data_ptr
  stax copy_src
  lda #0
  tay
  sta tcp_send_data_len
  sta tcp_send_data_len+1
  lda (copy_src),y
  bne @find_end_of_string
  rts ; if the string is empty, don't send anything!
@find_end_of_string:  
  lda (copy_src),y
  beq @done  
  inc tcp_send_data_len
  iny
  bne @find_end_of_string
@done:  
  ldax tcp_send_data_ptr
  ;now we can fall through into tcp_send

;send tcp data
;inputs:
;   tcp connection should already be opened
;   tcp_send_data_len: length of data to send (exclusive of any headers)
;   AX: pointer to buffer containing data to be sent
;outputs:
;   carry flag is set if an error occured, clear otherwise  
tcp_send:
	stax tcp_send_data_ptr
	
	;are we connected?
	ldax #W5100_S1_SR
	jsr w5100_read_register
	cmp #W5100_STATUS_SOCK_ESTABLISHED
	beq	@ok

  	lda #KPR_ERROR_CONNECTION_CLOSED
  	sta ip65_error
  	sec
  	rts
@ok:

	
	lda #$AD	;opcode for LDA
	sta next_eth_packet_byte
	
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
	adc	#$50
	sta tx_wr_ptr+1
:

	lda	byte_ctr_lo
	cmp	tcp_send_data_len
	bne	@send_next_byte
	lda	byte_ctr_hi
	cmp	tcp_send_data_len+1
	bne	@send_next_byte	

;all bytes copied, now adjust the tx write ptr and SEND
	jsr @get_current_tx_wr	
	clc	
	lda	tx_wr_ptr
	adc tcp_send_data_len
	sta tx_wr_ptr
	lda	tx_wr_ptr+1
	adc tcp_send_data_len+1
	tay
	ldax #W5100_S1_TX_WR0
	jsr	w5100_write_register
	ldy tx_wr_ptr
	ldax #W5100_S1_TX_WR1
	jsr	w5100_write_register
	ldax #W5100_S1_CR
 	ldy	#W5100_CMD_SEND
 	jsr	w5100_write_register
	
	clc
	rts

@get_current_tx_wr:
	ldax #W5100_S1_TX_WR0
	jsr	w5100_read_register	
	sta tx_wr_ptr+1
	ldax #W5100_S1_TX_WR1
	jsr	w5100_read_register
	sta tx_wr_ptr
	rts

;send an empty ACK packet on the current connection
;inputs:
;   none
;outputs:
;   carry flag is set if an error occured, clear otherwise

tcp_send_keep_alive:
	;are we connected?
	ldax #W5100_S1_SR
	jsr w5100_read_register
	cmp #W5100_STATUS_SOCK_ESTABLISHED
	beq	@ok

  	lda #KPR_ERROR_CONNECTION_CLOSED
  	sta ip65_error
  	sec
  	rts
@ok:
	ldax #W5100_S1_CR
	ldy	#W5100_CMD_SEND_KEEP
	jsr	w5100_write_register
	clc
	rts
	


  
;close the current connection
;inputs:
;   none
;outputs:
;   carry flag is set if an error occured, clear otherwise
tcp_close:

	ldax #W5100_S1_CR
	ldy	#W5100_CMD_DISCONNECT
	jsr	w5100_write_register
	clc
	rts


;poll the TCP socket
;if there is data available, call the user supplied TCP callback
;inputs:
;   none
;outputs:
;   carry flag is set if there was data, clear otherwise
tcp_rx:

	;is there data?
	ldax #W5100_S1_RX_RSR0 
	jsr	w5100_read_register
	sta	tcp_inbound_data_length+1
	ldax #W5100_S1_RX_RSR1
	jsr	w5100_read_register
	sta	tcp_inbound_data_length
	bne	@got_data
	lda	tcp_inbound_data_length+1
	bne	@got_data
	
	;are we connected?
	ldax #W5100_S1_SR
	jsr w5100_read_register
	cmp #W5100_STATUS_SOCK_ESTABLISHED
	beq	@connected_but_no_data
	;no longer connected
	lda #tcp_cxn_state_closed
	sta tcp_state
	
	lda #$ff
	sta tcp_inbound_data_length
	sta tcp_inbound_data_length+1
	jsr @make_fake_eth_header
	jsr jmp_to_callback   ;let the caller see the connection has closed
	sec			;don't poll the MAC RAW socket, else it may clobber the output buffer
	rts
@connected_but_no_data:
	clc	;no data - go check the MAC RAW socket
	rts
@got_data:
	lda #$8D	;opcode for STA
	sta next_eth_packet_byte

	ldax #eth_inp+$36	;we will write to the location that TCP data would appear if this was a raw eth frame,
						;14 bytes of ethernet header
						;20 bytes of IP header
						;20 bytes of TCP header
	
	stax tcp_inbound_data_ptr
	
	
	sta	eth_ptr_lo
	stx eth_ptr_hi
	
	lda	#0
	sta  byte_ctr_lo
	sta  byte_ctr_hi

	lda	tcp_inbound_data_length+1
	cmp	#4	;don't allow more than $4FF bytes at once ($1279) since we are writing to a 1500 byte 
	bmi	:+
	lda	#4
	sta	tcp_inbound_data_length+1
:	

	;now copy the data just arrived to the eth_inp buffer
	jsr	@get_current_rx_rd
	jsr @mask_and_adjust_rx_read
@get_next_byte:

	ldax rx_rd_ptr
	jsr	w5100_read_register
	jsr next_eth_packet_byte
	
	jsr @inc_rx_rd_ptr
	
	inc	byte_ctr_lo
	bne	:+
	inc	byte_ctr_hi
:	

	lda	byte_ctr_lo
	cmp	tcp_inbound_data_length
	bne	@get_next_byte
	lda	byte_ctr_hi
	cmp	tcp_inbound_data_length+1
	bne	@get_next_byte

	
;update the RX RD pointer past the frame we just read	
	jsr	@get_current_rx_rd
	clc	
	lda	rx_rd_ptr
	adc tcp_inbound_data_length
	sta rx_rd_ptr
	lda	rx_rd_ptr+1
	adc tcp_inbound_data_length+1
	tay
	ldax #W5100_S1_RX_RD0
	jsr	w5100_write_register
	ldy rx_rd_ptr
	
	ldax #W5100_S1_RX_RD1
	jsr	w5100_write_register
	ldax #W5100_S1_CR
 	ldy	#W5100_CMD_RECV
	jsr	w5100_write_register

	jsr @make_fake_eth_header
	jsr jmp_to_callback   ;let the caller see the connection has closed
	sec			;don't poll the MAC RAW socket, else it may clobber the output buffer
	rts
	
@inc_rx_rd_ptr:
	inc	rx_rd_ptr
	bne	:+
	inc	rx_rd_ptr+1
@mask_and_adjust_rx_read:
	lda rx_rd_ptr+1
	and	#$0F
	clc
	adc	#$70
	sta rx_rd_ptr+1
:	
	rts
	
@get_current_rx_rd:
	ldax #W5100_S1_RX_RD0
	jsr	w5100_read_register	
	sta rx_rd_ptr+1
	ldax #W5100_S1_RX_RD1
	jsr	w5100_read_register
	sta rx_rd_ptr
	rts

;the function dispatcher (and possibly other parts of the ip65 stack) expect to find valid values in the eth_inp frame
;when processing tcp data
@make_fake_eth_header:

	.import	ip_inp
	.import udp_inp
	;first set the TCP protocol value
	lda #6	;TCP protocol number
	sta ip_inp+9 ;proto number
	
	;now copy the remote IP address
	ldx	#0
@ip_loop:	
	lda	tcp_remote_ip,x
	sta ip_inp+12,x  ;src IP 
	inx
	cpx #$04
	bne	@ip_loop	
	
	;now the local & remote ports
	lda tcp_connect_remote_port
	sta udp_inp+1 ;remote port (lo byte)
	lda tcp_connect_remote_port+1	
	sta udp_inp+0 ;remote port (high byte)
	lda tcp_local_port
	sta udp_inp+3 ;local port (lo byte)
	lda tcp_local_port+1
	sta udp_inp+2 ;local port (high byte)
	
	rts

jmp_to_callback:
  jmp (tcp_callback)


;copy the IP65 configuration to the the w5100 onchip configuration
;we assume MAC has been configured already via eth_init, but IP
;address etc may not be known when the w5100 was initialised (e.g.
;if using DHCP).
w5100_set_ip_config:
	ldax #W5100_GAR0
	jsr	w5100_select_register
	ldx	#0
@gateway_loop:	
	lda	cfg_gateway,x
	sta WIZNET_DATA_REG
	inx
	cpx #$04
	bne	@gateway_loop
	ldx	#0	
@netmask_loop:	
	lda	cfg_netmask,x
	sta WIZNET_DATA_REG
	inx
	cpx #$04
	bne	@netmask_loop
	
	ldax #W5100_SIPR0
	jsr	w5100_select_register
	ldx	#0
@ip_loop:	
	lda	cfg_ip,x
	sta WIZNET_DATA_REG
	inx
	cpx #$04
	bne	@ip_loop
	rts

setup_tcp_socket:	
	jsr w5100_set_ip_config
	ldax #W5100_S1_PORT0
	jsr	w5100_select_register
	lda tcp_local_port+1
	sta WIZNET_DATA_REG
	lda tcp_local_port
	sta WIZNET_DATA_REG
	
	lda #0
	sta tcp_state

	ldax #W5100_S1_MR
	ldy	#W5100_MODE_TCP
	jsr	w5100_write_register
	
	;open socket 1
	ldax #W5100_S1_CR
	ldy	#W5100_CMD_OPEN
	jsr	w5100_write_register	
	rts

	
.rodata
eth_driver_name:
	.asciiz "RR-NET MK3 (WIZNET 5100)"

eth_driver_io_base:
	.word WIZNET_BASE

w5100_config_data:	
  .byte $00  ;no interrupts 
  .byte $0f  ;400ms retry (default)
  .byte $a0
  .byte $08  ;# of timeouts
  .byte $55  ;4 sockets @2K each, tx/rx
  .byte $55


;
; select one of the W5100 registers for subsequent read or write
; inputs: AX = register number to select
; outputs: none
w5100_select_register:
set_hi:
	stx WIZNET_ADDR_HI
set_lo:
	sta WIZNET_ADDR_LO
	rts

; return which W5100 register the next read or write will access
; inputs: none
; outputs: AX = selected register number
w5100_get_current_register:	
get_hi:
	ldx WIZNET_ADDR_HI
get_lo:
	lda WIZNET_ADDR_LO
	rts


.segment "SELF_MODIFIED_CODE"

next_eth_packet_byte:
	lda	$FFFF	;eth_packet
	jmp advance_eth_ptr
	
eth_ptr_lo=next_eth_packet_byte+1
eth_ptr_hi=next_eth_packet_byte+2

; .bss
; don't use BSS because we are out of room in the location that lives in the
; config used for 16K carts ($C010..$CFFF)
;there seems to be a little room still free in the seg used for SELF_MODIFIED_CODE

 w5100_addr: .res 2
 byte_ctr_lo: .res 1
 byte_ctr_hi: .res 1
 
 tx_wr_ptr: .res 2
 rx_rd_ptr: .res 2
tcp_local_port: .res 2

tcp_state: .res 1

tcp_connect_ip: .res 4 ;ip address of remote server to connect to
tcp_callback: .res 2 ;vector to routine to be called when data is received over tcp connection

tcp_remote_port: .res 2 ;temp space for holding port to listen on or connect to
tcp_send_data_len: .res 2
tcp_send_data_ptr = eth_ptr_lo


tcp_inbound_data_length: .res 2
tcp_inbound_data_ptr: .res 2

tcp_connect_remote_port: .res 2
tcp_remote_ip = tcp_connect_ip

tcp_cxn_state_closed      = 0 
tcp_cxn_state_listening   = 1  ;(waiting for an inbound SYN)
tcp_cxn_state_syn_sent    = 2  ;(waiting for an inbound SYN/ACK)
tcp_cxn_state_established = 3  ;  


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
