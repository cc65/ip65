
.include "../inc/common.i"
.include "../inc/commonprint.i"

VARTAB=$2D		;BASIC variable table storage
ARYTAB=$2F		;BASIC array table storage
FREETOP=$33		;bottom of string text storage area
MEMSIZ=$37		;highest address used by BASIC
CLEAR=$A65E		;clears BASIC variables
SETNAM=$FFBD
SETLFS=$FFBA 
OPEN=$FFC0
CHKIN=$FFC6
READST=$FFB7     ; read status byte
CHRIN=$FFCF     ; get a byte from file
CLOSE=$FFC3

.import copymem
.importzp copy_dest
.import dhcp_init
.import ip65_init
.import cfg_get_configuration_ptr
.import tcp_listen
.import tcp_callback
.import tcp_connect_ip
.import tcp_send
.import tcp_connect
.import tcp_close
.import tcp_send_data_len
.import tcp_inbound_data_ptr
.import tcp_inbound_data_length
.import dns_set_hostname
.import dns_resolve
.import dns_ip
.import ip65_process

.zeropage
temp_buff: .res 2

.segment "STARTUP"    ;this is what gets put at the start of the file on the C64
.word jump_table		; load address
jump_table:
	jmp	init	              ; $4000 (PTR) - vars io$,io%,er% should be created (in that order!) before calling
  jmp listen_on_port      ; $4003 (PTR+3) - io% is port to listen on
  jmp send_data           ; $4006 (PTR+6) - io$ is string to send
  jmp check_for_data      ; $4009 (PTR+9) - after return, io% 0 means no new data, 1 means io$ set to new data
  jmp connect_to_server   ; $400c (PTR+12) - io$ is remote server name or ip, io% is remote port
  jmp send_file           ; $400f (PTR+15) - io$ is name of file (on last accessed drive) to send over current channel
  jmp close_connection    ; $4002 (ptr+18) - no inputs needed
.code

init:
	
	
	;IO$,IO% and ER% should be first three variables created!
	
	lda #14
	jsr print_a ;switch to lower case 

	ldax #init_msg+1
	jsr print_ascii_as_native
  
  jsr ip65_init
	bcs @init_failed
  jsr dhcp_init
  bcc @init_ok
  jsr ip65_init   ;if DHCP failed, then reinit the IP stack (which will reset IP address etc that DHCP messed with to cartridge default values)
  bcc @init_ok
@init_failed:  
  print_failed
  jsr print_errorcode
  jmp		set_error_var
@init_ok:
  jsr print_ip_config
	
exit_to_basic:	
	rts
	
  
setup_for_tcp:
  ldax #tcp_data_arrived
  stax tcp_callback
  lda #0
  sta ip65_error
  rts
listen_on_port:
  
  jsr setup_for_tcp
  jsr get_io_var
  jsr tcp_listen
  bcs @error
  ldax #connected
  jsr print_ascii_as_native
  ldax #tcp_connect_ip
  jsr print_dotted_quad
  jsr print_cr
  lda #0
  sta ip65_error
  
@error:
  jmp set_error_var
  
send_data:
  jsr get_io_string_ptr
  sty tcp_send_data_len
  ldy #0
  sty tcp_send_data_len+1

  jsr tcp_send
  bcs @error
  lda #0
  sta ip65_error
@error:  
  jmp set_error_var
  
  
set_error_var:
	ldy		#16 ;we want to set 3rd & 4th byte of 3rd entry in variable table entry
	ldx 	#0	
	lda		ip65_error
	jmp	set_var

set_io_var:
	ldy		#9 ;we want to set 3rd & 4th byte of 2nd entry in variable table entry
set_var:	
	pha
	txa
	sta		(VARTAB),y ; set high byte
	iny
	pla
	sta		(VARTAB),y ; set low byte
	rts
	
get_io_var:
	ldy		#9 ;we want to read 3rd & 4th byte of 2nd entry in variable table entry
	lda		(VARTAB),y ; set high byte
  tax
	iny
	lda		(VARTAB),y ; set low byte
	rts

get_io_string_ptr:
	ldy		#4 ;we want to read 1st entry in variable table entry
	lda		(VARTAB),y ; ptr high byte
  tax
	dey
	lda		(VARTAB),y ; ptr low byte
  pha
	dey
  
	lda		(VARTAB),y ; length
  tay
  pla
	rts

get_io_string:  ;we want to turn from a string prefixed by length to nul terminated
  jsr get_io_string_ptr
  stax  copy_src  
	ldax	#transfer_buffer
	stax	copy_dest
  lda #0
  sta (copy_dest),y     ;null terminate the string
  tax
  tya
  jmp copymem
      
set_io_string:
	stax	copy_src
	ldax	#transfer_buffer
	stax	copy_dest
	ldy		#0
@loop:
	lda		(copy_src),y
	beq		@done
	sta		(copy_dest),y	
	iny		
	bne		@loop
@done:
set_io_string_ptr:
	tya		;length of string copied
	ldy		#2 ;length is 2nd byte of variable table entry
	sta		(VARTAB),y
	iny
	lda		#<transfer_buffer
	sta		(VARTAB),y
	iny
	lda		#>transfer_buffer
	sta		(VARTAB),y
	
	rts
  
check_for_data:
  lda #0
  sta ip65_error
  jsr set_error_var
  sta data_arrived_flag
  jsr ip65_process
  bcc @no_error
  jsr set_error_var
@no_error:
  lda data_arrived_flag
  ldx #0
  jmp set_io_var
  
tcp_data_arrived:
  inc data_arrived_flag
  ldax #transfer_buffer
  stax  copy_dest
  ldax  tcp_inbound_data_ptr
  stax  copy_src
  lda   tcp_inbound_data_length
  ldx   tcp_inbound_data_length+1  
  beq @short_packet
  cpx #$ff
  bne @not_end_packet
  inc data_arrived_flag
  rts
@not_end_packet:
  lda #$ff
@short_packet:
  tay
  pha
  jsr set_io_string_ptr  
  pla
  ldx #0
  jmp copymem
  rts

connect_to_server:
  jsr get_io_string
  ldax  #transfer_buffer
  jsr dns_set_hostname 
  bcs @error
  jsr dns_resolve
  bcs @error
  ldx #4
@copy_dns_ip:
  lda dns_ip,y
  sta tcp_connect_ip,y
  iny
  dex  
  bne @copy_dns_ip
  jsr setup_for_tcp
  jsr get_io_var
  jsr tcp_connect
  
@error:  
  jmp set_error_var


send_file:
  jsr get_io_string_ptr ;AX ptr, Y is length
  stax  copy_src
  tya
  ldx copy_src
  ldy copy_src+1
  jsr SETNAM
  lda #$02      ; file number 2
  ldx $BA       ; last used device number
  bne @skip
  ldx #$08      ; default to device 8
@skip:
  ldy #$02      ; secondary address 2
  jsr SETLFS
  jsr OPEN
  bcs @error    ; if carry set, the file could not be opened
  ldx #$02      ; filenumber 2
  jsr CHKIN
  ldy #$00
@loop:   
  jsr READST
  bne @eof          ; either EOF or read error
  jsr CHRIN
  sta transfer_buffer,y
  iny 
  bne @loop
  ldax #$100
  stax  tcp_send_data_len  
  ldax  #transfer_buffer
  jsr tcp_send
  bcs @error_stored
  ldy #0
  jmp @loop
@eof:
  and #$40      ; end of file?
  beq @readerror
  lda #$00
  sty  tcp_send_data_len
  sta  tcp_send_data_len+1
  ldax  #transfer_buffer
  jsr tcp_send
  bcs @error_stored
  
@close:
  lda #0
@store_error:  
  sta ip65_error
@error_stored:  
  jsr set_error_var  
  lda #$02      ; filenumber 2
  jsr CLOSE        
  ldx #$00      ; filenumber 0 = keyboard
  jsr CHKIN ;keyboard now input device again
  rts
@error:
  lda #KPR_ERROR_DEVICE_FAILURE
  jmp @store_error
@readerror:
  lda #KPR_ERROR_FILE_ACCESS_FAILURE
  jmp @store_error

close_connection:
  jsr tcp_close
  bcs @error
  lda #0
  sta ip65_error
@error:
  jmp set_error_var  
  
.data
data_arrived_flag:  .byte 0

connected:
	.byte "connected - ",0
.bss
transfer_buffer: .res $100
