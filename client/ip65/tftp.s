;minimal tftp implementation (client only)
;supports file download (not upload) and custom directory listing (using non-standard tftp opcode of 0x65)


  TFTP_MAX_RESENDS=10
  TFTP_TIMER_MASK=$F8 ;mask lower two bits, means we wait for 8 x1/4 seconds

  .include "../inc/common.i"
.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif

  .exportzp tftp_filename
  .export tftp_load_address
  .export tftp_ip
  .export tftp_download
  .export tftp_directory_listing 
  .export tftp_data_block_length
  .export tftp_set_download_callback
  .export tftp_data_block_length
  .export tftp_clear_callbacks
  
	.import ip65_process
  .import ip65_error
  
	.import udp_add_listener
  .import udp_remove_listener

	.import udp_callback
	.import udp_send

	.import udp_inp
	.import ip_inp
	.importzp ip_src
  .importzp udp_src_port


	.importzp udp_data

	.import udp_send_dest
	.import udp_send_src_port
	.import udp_send_dest_port
	.import udp_send_len

	.import copymem
	.importzp copy_src
	.importzp copy_dest

  .import timer_read
  
	.segment "IP65ZP" : zeropage

tftp_filename: .res 2 ;name of file to d/l or filemask to get directory listing for
  
	.bss

;packet offsets
tftp_inp		= udp_inp + udp_data 
tftp_outp:	.res 128
;everything after filename in a request at a relative address, not fixed, so don't bother defining offset constants

tftp_server_port=69
tftp_client_port_low_byte: .res 1

tftp_load_address: .res 2 ;address file will be (or was) downloaded to
tftp_ip: .res 4 ;ip address of tftp server - set to 255.255.255.255 (broadcast) to send request to all tftp servers on local lan

tftp_data_block_length: .res 2
tftp_current_memloc: .res 2

; tftp state machine
tftp_initializing	= 1		    ; initial state
tftp_rrq_sent=2             ; sent the read request, waiting for some data
tftp_receiving_file=3       ; we have received the first packet of file data
tftp_complete=4             ; we have received the final packet of file data
tftp_error=5                ; we got an error

tftp_state:	.res 1		; current activity
tftp_timer:  .res 1
tftp_resend_counter: .res 1
tftp_break_inner_loop: .res 1
tftp_expected_block_number: .res 1
tftp_block_number_to_ack: .res 1
tftp_actual_server_port: .res 2   ;this is read from the reply  - it is not (usually) the port # we send the RRQ to
tftp_actual_server_ip: .res 4     ;this is read from the reply - it may not be the IP we sent to (e.g. if we send to broadcast)

tftp_just_set_new_load_address: .res 1

tftp_opcode: .res 2 ; will be set to 4 if we are doing a RRQ, or 7 if we are doing a DIR

.code

; query a tftp server for a directory listing (uses a non-standard tftp opcode,
; currently only supported by tftp server built in to 'netboot65' server)
; inputs:
;   tftp_ip: ip address of host to download from (set to 255.255.255.255 for broadcast)
;   tftp_filename: pointer to null terminated filemask  (e.g. "*.prg",0)
;   tftp_load_address: memory location that dir will be stored in (NB - this field is
;       ignored if a callback vector has been set with tftp_set_download_callback)
; outputs: carry flag is set if there was an error, clear otherwise
;   if a callback vector has been set with tftp_set_download_callback
;   then the specified routine will be called once for each 512 byte packet
;   sent from the tftp server (each time AX will point at data block just arrived,
;   and tftp_data_block_length will contain number of bytes in that data block)
;   otherwise, the buffer at tftp_load_address will be filled
;   with null-terminated strings containing the names of all files on the
;   server that matched the specified file mask, and an additional null
;   byte will follow the null byte terminating the last file name.
;   NB - there is no limit to the amount of memory this function will consume,
;   so depending on where tftp_load_address is set, there is potential to
;   overwrite other data or code
tftp_directory_listing:
  ldax  #$6500      ;opcode 65 = netboot65 DIR (non-standard opcode)
  jmp set_tftp_opcode

;download a file from a tftp server
; inputs:
;   tftp_ip: ip address of host to download from (set to 255.255.255.255 for broadcast)
;   tftp_filename: pointer to null terminated name of file to download
;   tftp_load_address: memory location that dir will be stored in, or $0000 to
;     treat first 2 bytes received from tftp server as memory address that rest
;     of file should be loaded into (e.g. if downloading a C64 'prg' file)
; outputs: carry flag is set if there was an error
;   if a callback vector has been set with tftp_set_download_callback
;   then the specified routine will be called once for each 512 byte packet
;   sent from the tftp server (each time AX will point at data block just arrived,
;   and tftp_data_block_length will contain number of bytes in that data block)
;   otherwise, the buffer at tftp_load_address will be filled
;   with file downloaded.
;   tftp_load_address: will be set to the actual address loaded into (NB - this field is
;       ignored if a callback vector has been set with tftp_set_download_callback)
tftp_download:
  ldax  #$0100      ;opcode 01 = RRQ
set_tftp_opcode:  
  stax  tftp_opcode
  lda #tftp_initializing
  sta tftp_state  
  sta tftp_expected_block_number ;(tftp_initializing=1)
  ldax tftp_load_address
  stax tftp_current_memloc
  ldax #tftp_in
	stax udp_callback 
  lda #$69
  inc tftp_client_port_low_byte    ;each call to resolve uses a different client address
	ldx tftp_client_port_low_byte    ;so we don't get confused by late replies to a previous call
	jsr udp_add_listener
  
	bcc :+      ;bail if we couldn't listen on the port we want
  lda #NB65_ERROR_PORT_IN_USE
  sta ip65_error
	rts
:

  lda #TFTP_MAX_RESENDS
  sta tftp_resend_counter
@outer_delay_loop:
  jsr timer_read
  txa
  and #TFTP_TIMER_MASK
  sta tftp_timer            ;we only care about the high byte  
  lda #0
  sta tftp_break_inner_loop
  lda tftp_state
  cmp #tftp_initializing
  bne @not_initializing
  jsr send_request_packet
  jmp @inner_delay_loop
  
@not_initializing:
  cmp #tftp_error
  bne @not_error

@exit_with_error:
  lda #$69
	ldx tftp_client_port_low_byte    
	jsr udp_remove_listener  
  sec
  rts
  
@not_error:
  
  cmp #tftp_complete
  bne @not_complete
  jsr send_ack    ;send the ack for the last block
  lda #$69
	ldx tftp_client_port_low_byte    
	jsr udp_remove_listener  
  rts
  
@not_complete:  
  cmp #tftp_receiving_file
  bne @not_receiving
  jsr send_ack
  jmp @inner_delay_loop
@not_receiving:
  jsr send_request_packet  

@inner_delay_loop:    
  
  jsr ip65_process  
  lda tftp_break_inner_loop
  bne @outer_delay_loop
  jsr timer_read
  txa
  and #TFTP_TIMER_MASK
  cmp tftp_timer            
  beq @inner_delay_loop
  
  dec tftp_resend_counter
  bne @outer_delay_loop
  lda #NB65_ERROR_TIMEOUT_ON_RECEIVE
  sta ip65_error
  jmp @exit_with_error  

send_request_packet:
  lda #tftp_initializing
	sta tftp_state
  ldax  tftp_opcode  
  stax tftp_outp
  
  ldx #$01          ;we inc x/y at start of loop, so
  ldy #$ff          ;set them to be 1 below where we want the copy to begin
@copy_filename_loop:
  inx
  iny
  bmi @error_in_send  ;if we get to 0x80 bytes, we've gone too far
  lda (tftp_filename),y
  sta tftp_outp,x
  bne @copy_filename_loop

  ldy #$ff
@copy_mode_loop:
  inx
  iny
  lda tftp_octet_mode,y
  sta tftp_outp,x
  bne @copy_mode_loop
  
  inx 
  txa
  ldx #0
  stax udp_send_len
  
  lda #$69
	ldx tftp_client_port_low_byte    
	stax udp_send_src_port

  ldx #3				; set destination address
: lda tftp_ip,x
	sta udp_send_dest,x
	dex
	bpl :-

	ldax #tftp_server_port			; set destination port
	stax udp_send_dest_port
  ldax #tftp_outp
	jsr udp_send
  bcs @error_in_send
  lda #tftp_rrq_sent
  sta tftp_state
  rts
@error_in_send:  
  lda #NB65_ERROR_TRANSMIT_FAILED
  sta ip65_error
  sec
  rts

send_ack:
  ldax  #$0400      ;opcode 04 = ACK
  stax tftp_outp
  ldx tftp_block_number_to_ack
  stax  tftp_outp+2 
  lda #$69
	ldx tftp_client_port_low_byte    
	stax udp_send_src_port
  
  lda tftp_actual_server_ip
  sta udp_send_dest
  lda tftp_actual_server_ip+1
  sta udp_send_dest+1
  lda tftp_actual_server_ip+2
  sta udp_send_dest+2
  lda tftp_actual_server_ip+3
  sta udp_send_dest+3
  ldx tftp_actual_server_port
  lda tftp_actual_server_port+1
	stax udp_send_dest_port
  ldax #04
  stax udp_send_len

  ldax #tftp_outp
	jsr udp_send
  rts
  
  
tftp_in:
    
  lda tftp_inp+1  ;get the opcode
  cmp #5
  bne @not_an_error
@recv_error:
  lda #tftp_error
  sta tftp_state
  lda #NB65_ERROR_TRANSMISSION_REJECTED_BY_PEER
  sta ip65_error  
  rts
@not_an_error:

  cmp #3  
  beq :+
  jmp @not_data_block
:  

  
  lda #0
  sta tftp_just_set_new_load_address ;clear the flag
  clc 
  lda tftp_load_address       
  adc tftp_load_address+1     ;is load address currently $0000?
  bne @dont_set_load_address
  
  lda tftp_callback_address_set ;have we overridden the default handler?
  bne @dont_set_load_address  ;if so, don't skip the first two bytes in the file
  
  ldax udp_inp+$0c            ;get first two bytes of data
  stax tftp_load_address      ;make them the new load adress
  stax tftp_current_memloc    ;also the current memory destination
  lda #1                      ;set the flag
  sta tftp_just_set_new_load_address 

@dont_set_load_address:
  lda tftp_inp+3                  ;get the (low byte) of the data block
  
;  bmi @recv_error                 ;if we get to block $80, we've d/led more than 64k!
  cmp tftp_expected_block_number
    beq :+
  jmp @not_expected_block_number
:  
  ;this is the block we wanted
  sta tftp_block_number_to_ack
  inc tftp_expected_block_number
  lda #tftp_receiving_file
  sta tftp_state
  lda #TFTP_MAX_RESENDS
  sta tftp_resend_counter
  lda #1
  sta tftp_break_inner_loop

  ldax  udp_inp+udp_src_port
  stax  tftp_actual_server_port
  ldax  ip_inp+ip_src
  stax  tftp_actual_server_ip
  ldax  ip_inp+ip_src+2
  stax  tftp_actual_server_ip+2
      
  
  lda tftp_just_set_new_load_address 
  bne @skip_first_2_bytes_in_calculating_header_length
  lda udp_inp+5        ;get the low byte of udp packet length
  sec
  sbc #$0c              ;take off the length of the UDP header+OPCODE + BLOCK 

  jmp @adjusted_header_length
@skip_first_2_bytes_in_calculating_header_length:  
  lda udp_inp+5        ;get the low byte of udp packet length
  sec
  sbc #$0e              ;take off the length of the UDP header+OPCODE + BLOCK + first 2 bytes (memory location)
@adjusted_header_length:

  sta tftp_data_block_length
  lda udp_inp+4        ;get high byte of the length of the UDP packet
  sbc #0
  sta tftp_data_block_length+1

  lda tftp_just_set_new_load_address 
  bne @skip_first_2_bytes_in_calculating_copy_src
  ldax #udp_inp+$0c
  jmp @got_pointer_to_tftp_data
@skip_first_2_bytes_in_calculating_copy_src:
  ldax #udp_inp+$0e
@got_pointer_to_tftp_data:
  
  jsr tftp_download_callback

  lda udp_inp+4         ;check the length of the UDP packet
  cmp #02
  bne @last_block
  
  lda udp_inp+5
  cmp #$0c
  bne @last_block
@not_data_block:
@not_expected_block_number:
  rts
  
@last_block:
  lda #tftp_complete
  sta tftp_state
  rts
  
  
;default handler when block arrives:
;copy to RAM
;assumes tftp_data_block_length has been set, and AX should point to start of data
copy_tftp_block_to_ram:
  stax copy_src
  ldax tftp_current_memloc
  stax  copy_dest
  ldax  tftp_data_block_length
  jsr copymem
  clc
  lda tftp_data_block_length  ;update the location where the next data will go
  adc tftp_current_memloc
  sta tftp_current_memloc
  lda tftp_data_block_length+1
  adc tftp_current_memloc+1
  sta tftp_current_memloc+1
  rts

;set up vector of routine to be called when each 512 packet arrives from tftp server
;when vector is called, AX will point to data that was downloaded, and
;tftp_data_block_length will be set to length of downloaded data block. This will be 
;equal to $200 (512) for each block EXCEPT the final block. THe final block will
;always be less than $200 bytes - if the file is an exact multiple if $200 bytes
;long, then a final block will be received with length $00.
; inputs:
; AX - address of routine to call for each packet.
; outputs: none
tftp_set_download_callback:
  stax  tftp_download_callback+1
  rts
  
;clear callback vectors, i.e. all future transfers read from/write to RAM
;inputs: none
;outputs: none
tftp_clear_callbacks:
  ldax #copy_tftp_block_to_ram
  jmp tftp_set_download_callback

.rodata
  tftp_octet_mode: .asciiz "OCTET"
  
.data
tftp_download_callback:
    jmp copy_tftp_block_to_ram  ;vector for action to take when a data block received (default is to store block in RAM)

tftp_callback_address_set:  .byte 0