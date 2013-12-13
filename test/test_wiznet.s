	.include "../inc/common.i"
	.include "../inc/commonprint.i"
	.include "../inc/net.i"
	.include "../drivers/w5100.i"
	
	.import exit_to_basic  
	
	.import cfg_get_configuration_ptr
	.import copymem
	.importzp copy_src
	.importzp copy_dest
	.import icmp_echo_ip
	.import icmp_ping
	.import get_key_ip65
	.import w5100_ip65_init
	.import w5100_read_register	
	.import dns_set_hostname
	.import dns_resolve
	.import dns_ip
	.import dns_status

  	.import tcp_connect
	.import tcp_connect_ip
	.import tcp_callback
	.import tcp_send_string
	.import tcp_close
	.import tcp_inbound_data_ptr
	.import tcp_inbound_data_length
	.import tcp_connect_remote_port
	.import tcp_remote_ip
	.import tcp_listen
	.importzp acc16	
	.import cmp_16_16

  
	.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

	.word basicstub		; load address

basicstub:
	.word @nextline
	.word 2003
	.byte $9e
	.byte <(((init / 1000) .mod 10) + $30)
	.byte <(((init / 100 ) .mod 10) + $30)
	.byte <(((init / 10  ) .mod 10) + $30)
	.byte <(((init       ) .mod 10) + $30)
	.byte 0
@nextline:
	.word 0

.code

init:
	
	ldax #starting
	jsr	print
@loop:
	inc	$d020
	jmp	@loop
	
	
	ldax #$DE00
	jsr	probe_for_w5100
	bcc	@found
	ldax #$DF00
	jsr	probe_for_w5100
	bcc	@found	
	ldax #$DF20
	jsr	probe_for_w5100
	bcc	@found
	ldax	#no_wiznet
	jmp	print
	rts
	
@found:	
	jsr dhcp_init
	lda #0
	jsr dump_wiznet_register_page
	lda #4
	jsr dump_wiznet_register_page

@skip:


  jsr print_ip_config

	jsr	ping_test
	jsr	ping_test_2

	jsr tcp_listen_test

	ldax #hostname_1
	jsr do_dns_query  
	bcs	:+
	jsr	ping_test_3
	jsr	tcp_test
:
	rts


tcp_listen_test:
	
	ldax  #tcp_callback_routine
	stax  tcp_callback
	ldax	#listening
	jsr	print
	ldax	#80
	
	jsr	tcp_listen
	bcc	:+
	ldax #error	
	jsr	print
	lda	ip65_error
	jsr	print_hex
	jsr	print_cr
	rts
:

	ldax #connection_from
	jsr print
	ldax #tcp_remote_ip
	jsr print_dotted_quad
	lda #':'
	jsr print_a
	ldax tcp_connect_remote_port
	jsr print_integer
	jsr	print_cr
	jmp send_tcp_data

tcp_test:
	
	ldax  #tcp_callback_routine
	stax  tcp_callback

	;send without connecting - should get an error
	ldax #http_string1
	jsr	tcp_send_string
	bcc	:+
	ldax #error	
	jsr	print
	lda	ip65_error
	jsr	print_hex
	jsr	print_cr
:
  ldx #$3
:
	lda dns_ip,x
	sta tcp_connect_ip,x
	dex
	bpl :-  
	ldax #connecting
	jsr	print

	ldax #tcp_connect_ip
	jsr print_dotted_quad
	jsr	print_cr
	
	
	ldax #80	;port number

	jsr	tcp_connect
	bcc	@no_error
	ldax #error	
	jsr	print
	lda	ip65_error
	jsr	print_hex
	jsr	print_cr
	lda #0
	jsr dump_wiznet_register_page
	lda #5
	jsr dump_wiznet_register_page

  	rts
@no_error:	

send_tcp_data:
	lda #0
	sta cxn_closed

	ldax #sending
	jsr	print
	ldax #http_string1
	jsr	print
	ldax #http_string1
	jsr	tcp_send_string
	bcc	@ok1

@error:	
	ldax #error	
	jsr	print
	lda	ip65_error
	jsr	print_hex
	jsr	print_cr
@done:	
	lda #0
	jsr dump_wiznet_register_page
	lda #5
	jsr dump_wiznet_register_page

  	rts
 
 @ok1:
	ldax #sending
	jsr	print
	ldax #http_string2
	jsr	print
	ldax #http_string2
	jsr	tcp_send_string
	bcs	@error
@poll_loop:
	jsr	ip65_process
	lda	cxn_closed
	beq	@poll_loop
 	jsr	tcp_close
	ldax #EOF
	jsr	print
 	
 	jmp	@done

ping_test:
  ldx #$3
:
  lda dhcp_server,x
  sta icmp_echo_ip,x
  dex
  bpl :-  
  jmp	do_ping	 
  
ping_test_2:
  ldx #$3
:
  lda cfg_gateway,x
  sta icmp_echo_ip,x
  dex
  bpl :-  
  jmp	do_ping	 

ping_test_3:
  ldx #$3
:
  lda dns_ip,x
  sta icmp_echo_ip,x
  dex
  bpl :-  
  jmp	do_ping	 
  
 
do_ping: 
  ldax #pinging
  jsr print
  
  ldax #icmp_echo_ip
  jsr print_dotted_quad
  jsr print_cr
  jsr icmp_ping
  bcs @error
  jsr print_integer
  ldax #ms
  jsr print
  rts
@error:
  jmp print_errorcode

 rts


probe_for_w5100:
  stax w5100_addr
  ldax	#probing
  jsr	print
  lda	w5100_addr+1
  jsr	print_hex
  lda	w5100_addr
  jsr	print_hex
  jsr	print_cr
  ldax w5100_addr
  jmp	w5100_ip65_init

wait_for_keypress:
  lda #0
  sta $c6 ;set the keyboard buffer to be empty
  ldax  #press_a_key_to_continue
  jsr print
  jsr get_key_ip65  
  rts



do_dns_query:
	pha
	jsr print
	lda #' '
	jsr print_a
	lda #':'
	jsr print_a
	lda #' '
	jsr print_a
	pla
	jsr dns_set_hostname
	jsr dns_resolve
	bcc :+
	ldax #dns_lookup_failed_msg
	jsr print
	lda #0
	jsr dump_wiznet_register_page
	lda #5
	jsr dump_wiznet_register_page
	
	sec
	rts
:  
  ldax #dns_ip
  jsr print_dotted_quad
  jsr	print_cr
  clc
  rts


dump_wiznet_register_page:
  sta register_page
  lda #0
  sta current_register
   jsr print_cr

@one_row:
  lda current_register
  cmp #$20
  beq @done
  lda register_page
  jsr print_hex
  lda current_register  
  jsr print_hex
  lda #':'
  jsr print_a
  lda #' '
  jsr print_a

  lda #0
  sta current_byte_in_row
  
@dump_byte:
  lda current_register
  ldx register_page
  jsr w5100_read_register
  jsr print_hex
  lda #' '
  jsr print_a
  inc current_register
  inc current_byte_in_row
  lda current_byte_in_row
  cmp #08
  bne @dump_byte
  
 jsr print_cr
  jmp @one_row
@done:
  jsr print_cr
  rts


tcp_callback_routine:
  
  lda tcp_inbound_data_length
  cmp #$ff
  bne @not_end_of_file
  lda #1
  sta cxn_closed
  rts
  
@not_end_of_file:
  lda #14
  jsr print_a ;switch to lower case
   
  
  ldax tcp_inbound_data_ptr
  stax get_next_byte+1
    
  lda #0
  sta byte_counter
  sta byte_counter+1
  
@print_one_byte:
  jsr get_next_byte  
  jsr ascii_to_native
  
  jsr print_a
  inc get_next_byte+1
  bne :+
  inc get_next_byte+2
:

  inc byte_counter
  bne :+
  inc byte_counter+1
:
  ldax  byte_counter
  stax  acc16
  ldax tcp_inbound_data_length
  jsr cmp_16_16
  bne @print_one_byte
  
  rts

get_next_byte: 
  lda $ffff
  rts

  
.rodata
starting: .byte "STARTING",13,0
ms: .byte " MS",13,0
pinging: .byte "PINGING ",0
connecting: .byte "CONNECTING ",0
sending: .byte "SENDING ",0
hello: .byte "HELLO WORLD!",13,10,0
no_wiznet: .byte "NO W5100 FOUND",13,10,0
probing: .byte "LOOKING FOR W5100 AT $",0
ping_ip: .byte 10,5,1,84
hostname_1: .byte "JAMTRONIX.COM",0     
error: .byte "ERROR $",0
ok: .byte "OK",13,0
EOF: .byte "CONNECTION CLOSED",13,0
listening: .byte "LISTENING ON PORT 80",13,0
http_string1: .byte "GET ",0
connection_from: .byte "CONNECTION FROM ",0
http_string2: .byte "/ HTTP/1.0",13,10,13,10,0
.bss
w5100_addr: .res 2
current_register:.res 1
current_byte_in_row: .res 1
register_page: .res 1
cxn_closed: .res 1
byte_counter: .res 2



;-- LICENSE FOR test_ping.s --
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
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
