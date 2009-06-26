;TCP (transmission control protocol) functions

.include "../inc/common.i"
.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif

.import ip65_error

.export tcp_init
.export tcp_process
.export tcp_listen
.export tcp_connect
.export tcp_callback
.export tcp_remote_ip

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


.segment "TCP_VARS"

tcp_cxn_state_listening   = 1  ;(waiting for an inbound SYN)
tcp_cxn_state_syn_sent    = 2  ;(waiting for an inbound SYN/ACK)
  

; tcp packet offsets
tcp_inp		= ip_inp + ip_data  ;pointer to tcp packet inside inbound ethernet frame
tcp_outp	= ip_outp + ip_data ;pointer to tcp packet inside outbound ethernet frame
tcp_src_port	= 0 ;offset of source port field in tcp packet
tcp_dest_port	= 2 ;offset of destination port field in tcp packet
tcp_seq		= 4 ;offset of sequence number field in tcp packet
tcp_ack	= 8 ;offset of acknowledgement field in tcp packet
tcp_header_length	= 12 ;offset of header length field in tcp packet
tcp_flags_field	= 13 ;offset of flags field in tcp packet
tcp_window_size = 14 ; offset of window size field in tcp packet
tcp_checksum = 16 ; offset of checksum field in tcp packet
tcp_urgent_pointer = 18 ; offset of urgent pointer field in tcp packet
tcp_data=20   ;offset of data in tcp packet 

; virtual header
tcp_vh		= tcp_outp - 12
tcp_vh_src	= 0
tcp_vh_dest	= 4
tcp_vh_zero	= 8
tcp_vh_proto	= 9
tcp_vh_len	= 10

;
tcp_flag_FIN  =1
tcp_flag_SYN  =2
tcp_flag_RST  =4
tcp_flag_PSH  =8
tcp_flag_ACK  =16
tcp_flag_URG  =32




.segment "TCP_VARS"
tcp_state:  .res 1
tcp_local_port: .res 2
tcp_remote_port: .res 2
tcp_remote_ip: .res 4
tcp_sequence_number: .res 4
tcp_ack_number: .res 4
tcp_data_ptr: .res 2
tcp_data_len: .res 2
tcp_callback: .res 2
tcp_flags: .res 1
.data
tcp_client_port: .word $0004  ;=$0400 in network byte order

.code

tcp_init:
  
  rts

;make outbound tcp connection
;inputs:
; tcp_remote_ip:  destination ip address (4 bytes)
; AX: destination port (2 bytes)
; tcp_callback: vector to call when data arrives on this connection
;outputs:
;   carry flag is set if an error occured, clear otherwise
tcp_connect:
  stax  tcp_remote_port  
  inc   tcp_client_port
  ldax  tcp_client_port
  stax  tcp_local_port
  lda #tcp_cxn_state_syn_sent
  sta tcp_state
  lda #tcp_flag_SYN
  sta tcp_flags
  ldax  #0
  stax  tcp_data_len
  stax  tcp_ack_number
  stax  tcp_ack_number+2
  jsr tcp_send_packet
  rts


;send a single tcp packet 
;inputs:
; tcp_remote_ip: IP address of destination server
; tcp_remote_port: destination tcp port 
; tcp_local_port: source tcp port
; tcp_flags: 6 bit flags
; tcp_data_ptr: pointer to data to include in this packet
; tcp_data_len: length of data pointed at by tcp_data_ptr
;outputs:
;   carry flag is set if an error occured, clear otherwise
tcp_send_packet:
  ldax  tcp_data_ptr
  stax copy_src			; copy data to output buffer
	ldax #tcp_outp + tcp_data
	stax copy_dest
	ldax tcp_data_len
	jsr copymem

	ldx #3				; copy virtual header addresses
:	lda tcp_remote_ip,x
	sta tcp_vh + tcp_vh_dest,x	; set virtual header destination
	lda cfg_ip,x
	sta tcp_vh + tcp_vh_src,x	; set virtual header source
	dex
	bpl :-

	lda tcp_local_port		; copy source port
	sta tcp_outp + tcp_src_port + 1
	lda tcp_local_port + 1
	sta tcp_outp + tcp_src_port

	lda tcp_remote_port		; copy destination port
	sta tcp_outp + tcp_dest_port + 1
	lda tcp_remote_port + 1
	sta tcp_outp + tcp_dest_port

  ldx #3				; copy sequence and ack numbers (in reverse order)
  ldy #0
:	lda tcp_sequence_number,x
	sta tcp_outp + tcp_seq,y
	lda tcp_ack_number,x
	sta tcp_outp + tcp_ack,y
  iny
	dex
	bpl :-

  lda #$50    ;4 bit header length in 32bit words + 4 bits of zero
  sta tcp_outp+tcp_header_length
  lda tcp_flags
  sta tcp_outp+tcp_flags_field
  
	lda #ip_proto_tcp
	sta tcp_vh + tcp_vh_proto

  ldax  #$1000  
  stax  tcp_outp+tcp_window_size

	lda #0				; clear checksum
	sta tcp_outp + tcp_checksum
	sta tcp_outp + tcp_checksum + 1
	sta tcp_vh + tcp_vh_zero	; clear virtual header zero byte

	ldax #tcp_vh			; checksum pointer to virtual header
	stax ip_cksum_ptr

	lda tcp_data_len		; copy length + 20
	clc
	adc #20
	sta tcp_vh + tcp_vh_len + 1	; lsb for virtual header
	tay
	lda tcp_data_len + 1
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
	stax tcp_outp + tcp_checksum

	ldx #3				; copy addresses
:	lda tcp_remote_ip,x
	sta ip_outp + ip_dest,x		; set ip destination address
	dex
	bpl :-

	jsr ip_create_packet		; create ip packet template

	lda tcp_outp + tcp_data_len + 1	; ip len = tcp data length +20 byte ip header + 20 byte tcp header
	ldx tcp_outp + tcp_data_len
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


;listen on the tcp port specified
; tcp_callback: vector to call when data arrives on specified port
; AX: set to tcp port to listen on
tcp_listen:
  rts

tcp_process:
;process incoming tcp packet
;inputs:
; eth_inp: should contain an ethernet frame encapsulating an inbound tcp packet
;outputs:
; carry flag set if any error occured (including if packet not part of 
; existing connection)
; carry flag clear if no error
; if connection was found, an outbound message may be created, overwriting eth_outp
  rts
