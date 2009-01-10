;########################
; minimal tcp implementation 
; written by jonno@jamtronix.com 2009
;########################

.include "../inc/common.i"

  MAX_TCP_RETRY=10
  
	.export tcp_init
	.export tcp_process
	.export tcp_connect
;	.export tcp_close
	.export tcp_send

	.export tcp_callback

	.export tcp_inp
	.export tcp_outp

	.exportzp tcp_src_port
	.exportzp tcp_dest_port
;	.exportzp tcp_len
	.exportzp tcp_cksum
	.exportzp tcp_data

	.export tcp_send_dest
	.export tcp_send_src_port
	.export tcp_send_dest_port
	.export tcp_send_len


  .import ip65_process
  .import timer_read
	.import ip_calc_cksum
	.import ip_send
	.import ip_create_packet
	.import ip_inp
	.import ip_outp
	.importzp ip_cksum_ptr
	.importzp ip_header_cksum
	.importzp ip_src
	.importzp ip_dest
	.importzp ip_data
	.importzp ip_proto
	.importzp ip_proto_tcp
	.importzp ip_id
	.importzp ip_len

	.import copymem
	.importzp copy_src
	.importzp copy_dest

	.import cfg_ip


	.bss

; arguments for tcp_connect
tcp_callback:	.res 2
tcp_send_dest:		.res 4
tcp_send_src_port:	.res 2
tcp_send_dest_port:	.res 2

;data on current connection
tcp_current_seq_number: .res 4
tcp_last_ack_number: .res 4
tcp_expected_ack_number: .res 4
tcp_flags_value: .res 1

; arguments for tcp_send
tcp_send_len:		.res 2

; tcp packet offsets
tcp_inp		= ip_inp + ip_data
tcp_outp	= ip_outp + ip_data
tcp_src_port	= 0
tcp_dest_port	= 2
tcp_sequence_number=4
tcp_ack_number=8
tcp_flags=12
tcp_window_size=14
tcp_cksum	= 16
tcp_urgent_pointer	= 18
tcp_data=20


tcp_state: .res 1
tcp_state_listen=1
tcp_state_syn_sent=2
tcp_state_syn_received=3
tcp_state_established=4
tcp_state_fin_wait_1=5
tcp_state_fin_wait_2=6
tcp_state_close_wait=7
tcp_state_closing=8
tcp_state_last_ack=9
tcp_state_time_wait=10
tcp_state_closed=11

tcp_message_sent_count: .res 1
tcp_loop_count: .res 1
tcp_timer: .res 1

; virtual header
tcp_vh		= tcp_outp - 12
tcp_vh_src	= 0
tcp_vh_dest	= 4
tcp_vh_zero	= 8
tcp_vh_proto	= 9
tcp_vh_len	= 10

	.code

; initialize tcp
tcp_init:
  ;nothing to do here yet
rts


; process incoming tcp packet
tcp_process:
	rts


;connect to a remote server
; but first:
;
; set destination address
; set source port
; set destination port
; set callback address

tcp_connect:
  ldax #0
  stax  tcp_send_len
  sta tcp_message_sent_count
  lda #$02  ;SYN
  sta tcp_flags_value
  lda #tcp_state_syn_sent
  sta tcp_state
  
  jsr tcp_send

@tcp_polling_loop:
  lda tcp_message_sent_count
  adc #1
  sta tcp_loop_count       ;we wait a bit longer between each resend  
@outer_delay_loop: 
  jsr timer_read
  stx tcp_timer            ;we only care about the high byte  
  
@inner_delay_loop:  
  jsr ip65_process
  lda tcp_state
  cmp #tcp_state_syn_sent
  clc
  bne @done
  jsr timer_read
  cpx tcp_timer            ;this will tick over after about 1/4 of a second
  beq @inner_delay_loop
  
  dec tcp_loop_count
  bne @outer_delay_loop  

  jsr tcp_send
	inc tcp_message_sent_count
  lda tcp_message_sent_count
  cmp #MAX_TCP_RETRY-1
  bpl @too_many_retries
  jmp @tcp_polling_loop

@too_many_retries:
  sec
@done:  
  rts


; send tcp packet to currently open connection
;
; but first:
;
; set length

tcp_send:
	stax copy_src			; copy data to output buffer
	ldax #tcp_outp + tcp_data
	stax copy_dest
	ldax tcp_send_len
	jsr copymem


  lda tcp_flags_value 
  sta ip_outp +tcp_flags

	ldx #3				; copy virtual header addresses
:	lda tcp_send_dest,x
	sta tcp_vh + tcp_vh_dest,x	; set virtual header destination

	lda cfg_ip,x
	sta tcp_vh + tcp_vh_src,x	; set virtual header source
	dex
	bpl :-

	lda tcp_send_src_port		; copy source port
	sta tcp_outp + tcp_src_port + 1
	lda tcp_send_src_port + 1
	sta tcp_outp + tcp_src_port

	lda tcp_send_dest_port		; copy destination port
	sta tcp_outp + tcp_dest_port + 1
	lda tcp_send_dest_port + 1
	sta tcp_outp + tcp_dest_port

	lda #ip_proto_tcp
	sta tcp_vh + tcp_vh_proto

	lda #0				; clear checksum
	sta tcp_outp + tcp_cksum
	sta tcp_outp + tcp_cksum + 1
	sta tcp_vh + tcp_vh_zero	; clear virtual header zero byte

	ldax #tcp_vh			; checksum pointer to virtual header
	stax ip_cksum_ptr

	lda tcp_send_len		; copy length + 20
	clc
	adc #20
	sta tcp_vh + tcp_vh_len + 1	; lsb for virtual header
	tay
	lda tcp_send_len + 1
	adc #0
	sta tcp_vh + tcp_vh_len		; msb for virtual header

	tax				; length to A/X
	tya

	clc				; add 12 bytes for virtual header
	adc #12
	bcc :+
	inx
:
	jsr ip_calc_cksum		; calculate checksum
	stax tcp_outp + tcp_cksum

	ldx #3				; copy addresses
:	lda tcp_send_dest,x
	sta ip_outp + ip_dest,x		; set ip destination address
	dex
	bpl :-

  
	jsr ip_create_packet		; create ip packet template
  

	lda tcp_outp + tcp_send_len + 1	; ip len = tcp data len + 20 byte tcp header len + 20 byte ip header len
	ldx tcp_outp + tcp_send_len
	clc
	adc #40
	bcc :+
	inx
:	sta ip_outp + ip_len + 1	; set length
	stx ip_outp + ip_len

	ldax #$1234    			; set ID
	stax ip_outp + ip_id

	lda #ip_proto_tcp		; set protocol
	sta ip_outp + ip_proto


	jmp ip_send			; send packet, sec on error
