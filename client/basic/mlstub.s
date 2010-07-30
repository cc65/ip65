
.include "../inc/common.i"
.include "../inc/commonprint.i"

VARTAB=$2D		;BASIC variable table storage
ARYTAB=$2F		;BASIC array table storage
FREETOP=$33		;bottom of string text storage area
MEMSIZ=$37		;highest address used by BASIC
CLEAR=$A65E		;clears BASIC variables


.import copymem
.importzp copy_dest
.import dhcp_init
.import ip65_init
.import cfg_get_configuration_ptr
.import tcp_listen
.import tcp_callback
.import tcp_connect_ip
.import tcp_send
.import tcp_send_data_len
.zeropage
temp_buff: .res 2

.segment "STARTUP"    ;this is what gets put at the start of the file on the C64
.word jump_table		; load address
jump_table:
	jmp	init	              ; this should be at $4000 ie SYS 16384
  jmp listen_on_port      ; this should be at $4003 ie SYS 16387
  jmp send_data           ; this should be at $4006 ie SYS 16390
.code

init:
	
	
	;set up the transfer variables IO$,IO% and ER%
	
	;first make room 
	clc
	lda		VARTAB
	adc		#basic_vartable_entries_length/7
	sta		ARYTAB
	lda		VARTAB+1
	adc		#0
	sta		ARYTAB+1
	
	ldax	#basic_vartable_entries
	stax	copy_src
	ldax	VARTAB
	stax	copy_dest
	ldax	#basic_vartable_entries_length
	jsr 	copymem
	
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
	
  
listen_on_port:
  ldax #tcp_data_arrived
  stax tcp_callback
  lda #0
  sta ip65_error

  jsr get_io_var
  jsr tcp_listen
  bcs @error
  ldax #connected
  jsr print_ascii_as_native
  ldax #tcp_connect_ip
  jsr print_dotted_quad
  jsr print_cr
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

tcp_data_arrived:
  
  rts

.data

basic_vartable_entries:
	.byte $49,$CF ; IO$
	.byte	0 ;length 0
	.word   0; pointer
	.word 	0	;2 dummy bytes
	.byte $C9,$CF ; IO%
	.byte 	0 ;initial value HI
	.byte	0 ;initial value = LO
	.byte 	0,0,0	;3 dummy bytes

	.byte $C5,$D2 ; ER%
	.byte 	0 ;initial value HI
	.byte	0 ;initial value = LO
	.byte 	0,0,0	;3 dummy bytes

basic_vartable_entries_length=*-basic_vartable_entries
connected:
	.byte "connected - ",0
.bss
transfer_buffer: .res $100

