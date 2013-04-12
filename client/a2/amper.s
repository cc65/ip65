  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/a2const.i"
  .include "../inc/net.i"
  
  .import exit_to_basic  
  .import cfg_get_configuration_ptr
  .import dns_ip
  .import dns_resolve
  .import dns_set_hostname
  .import icmp_ping
  .import icmp_echo_ip

  
  .import copymem
  .importzp copy_src

  .importzp copy_dest
  .importzp buffer_ptr

  .import http_parse_request
  .import http_get_value
  .import http_variables_buffer

  .import tcp_inbound_data_ptr
  .import tcp_inbound_data_length
  .import tcp_send_data_len
  .import tcp_send
  .import check_for_abort_key
  .import tcp_connect_remote_port
  .import tcp_remote_ip
  .import tcp_listen
  .import tcp_callback
  .import tcp_close
  
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__ 
  .import  __DATA_SIZE__
  .import __IP65_DEFAULTS_SIZE__
  .import __BSS_RUN__ 
  .import __BSS_SIZE__ 
  
 END_OF_BSS =  __BSS_RUN__+__BSS_SIZE__

.segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-$03                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+__IP65_DEFAULTS_SIZE__+4	; file size
        jmp init
.code

init:
	jsr ip65_init
  	bcc @init_ok
  	ldax #@no_nic
  	jsr	print

	jmp exit_to_basic
@no_nic:
  .byte "NO NIC - UNINSTALLING",0  
@install_msg:
  .byte " FOUND",13,"APPLESOFT.NET USING $801-$"

  .byte 0
@init_ok:
	;print the banner
  	ldax #eth_driver_name
  	jsr print_ascii_as_native
	ldax #@install_msg
	jsr	print	
	print_hex_double #END_OF_BSS	
    jsr	print_cr  
    
    ;take over the ampersand vector
    ldax AMPERSAND_VECTOR+1
    stax old_amper_handler		
	ldax #amper_handler
	stax  AMPERSAND_VECTOR+1

	lda	#$FF
	sta	CURLIN+1	;put into 'immediate' mode
	ldax #END_OF_BSS+1
	stax TXTTAB
	lda	#0
	sta END_OF_BSS		;if the byte before the start of the BASIC is not zero, we 
						;get a weird 'SYNTAX ERROR IN LINE' because 
						;STXTPT (called by RUN) sets TXTPTR (address of next BASIC token) to be TXTTAB-1
						;if this byte is zero, then NEWSTT tries to execute that byte
	jsr	SCRTCH		;reset BASIC now we have updated the start address 
	lday #chain_cmd
	jsr STROUT
	jmp exit_to_basic

print_error:
  jsr print
  ldax #error
  jsr print
  lda ip65_error
  jsr print_hex
  jsr print_cr
  sec
  rts	
amper_handler:
	;see if & is followed by one of our keywords 	

    ldx #0 
    ldy #0 
    lda keyword_table

@check_one_handler:
    cmp #$FF ;end of table?
    beq	exit_to_old_handler
    cmp (TXTPTR),y ;char in line
    beq	@this_char_ok
@skip_to_next_handler_loop:	
	inx
	lda keyword_table,x 
	bne @skip_to_next_handler_loop
	inx	;skip first part of handler address
	inx	;skip next part of handler address
	ldy #$FF
@this_char_ok:
	iny 
    inx 
    lda keyword_table,x ;get cmd char
	bne @check_one_handler
	;if we get here, we have matched a keyword, and X points to the zero terminating the keyword, Y is length of keyword
    lda keyword_table+2,x ;get high byte of handler address
	pha
    lda keyword_table+1,x ;get low byte of handler address
    pha
    jmp ADDON ;fix-up TXTPTR - on return control will transfer to address we just pushed

exit_to_old_handler:
	jmp	$ffff
old_amper_handler=exit_to_old_handler+1
 
 get_optional_byte:  
  jsr CHRGOT
  beq @no_param ;leave X as it was
  jmp COMBYTE
@no_param:
  rts
 
extract_string:
  jsr FRMEVL
  jsr FRESTR  ;if not string, will create type mismatch error
  sta param_length
  tay
  lda #0
  sta transfer_buffer,y  
  dey
@loop:
  lda (INDEX),y
  sta transfer_buffer,y  
  dey  
  bpl @loop
  rts
  
get_ip_parameter:
  stax  buffer_ptr
  jsr extract_string
  ldax #transfer_buffer
  
  jsr dns_set_hostname   
  
  bcs @error
  jsr dns_resolve
  bcc @ok
@error:  
  ldax  #address_resolution
  jmp print_error

@ok:
  ldax #dns_ip
  ldx #4
@copy_dns_ip:
  lda dns_ip,y 
  sta (buffer_ptr),y  
  iny
  dex  
  bne @copy_dns_ip  
  rts

ipcfg_handler:
	jmp	print_ip_config
	
ping_handler:
  ldax  #icmp_echo_ip
  jsr get_ip_parameter
  bcc @no_error
  rts
@no_error:  
  ;is there an optional parameter?
  ldx #3
  jsr get_optional_byte
  stx ping_counter
  
  ldax #pinging
  jsr print
  ldax #dns_ip
  jsr print_dotted_quad
  jsr print_cr
  
@ping_loop:  
  jsr   icmp_ping
  bcs @error
  lda #'.'
@print_and_loop:  
  jsr print_a  
  lda $c000 ;key pressed
  sta $c010 ;clear keyboard
  cmp #$9B  ;escape
  beq @done
  dec ping_counter
  bne @ping_loop
@done:  
  jmp print_cr
@error:
  lda #'!'
  jmp @print_and_loop

  
dhcp_handler:
  jsr dhcp_init
  bcc @init_ok
  jsr ip65_init   ;if DHCP failed, then reinit the IP stack (which will reset IP address etc that DHCP messed with to default values)
  
@init_failed:  
  ldax  #dhcp
  jmp print_error
@init_ok:
 rts

myip_handler:
  ldax #cfg_ip
  jmp get_ip_parameter

dns_handler:
  ldax #cfg_dns
  jmp get_ip_parameter  

gateway_handler:
  ldax #cfg_gateway
  jmp get_ip_parameter
  
netmask_handler:
  ldax #cfg_netmask
  jmp get_ip_parameter  
  
 
skip_comma_get_integer:
  jsr CHKCOM
 get_integer: 
  jsr CHRGOT
  jsr LINGET 
  ldax LINNUM
  rts
	

httpd_handler:
  jsr flush_handler			;clean out the last connection
  jsr  get_integer
  stax httpd_port_number
  tsx
  stx top_of_stack
  
  ldax #listening
  jsr print
  ldax  #cfg_ip
  jsr print_dotted_quad
  lda #':'
  jsr print_a
  ldax httpd_port_number
  jsr print_integer
  jsr print_cr

@listen:
  jsr tcp_close
  ldax httpd_io_buffer
  stax tcp_buffer_ptr 
  
  ldax #http_callback
  stax tcp_callback
  ldax httpd_port_number
  
  jsr tcp_listen
  bcc @connect_ok
  jmp END4

@connect_ok: 
  ldax #connection_from
  jsr print
  ldax #tcp_remote_ip
  jsr print_dotted_quad
  lda #':'
  jsr print_a
  ldax tcp_connect_remote_port

  jsr print_integer
  jsr print_cr
  lda #0
  sta connection_closed
  sta found_eol
  sta polling_counter

@main_polling_loop:
  jsr ip65_process
  jsr ISCNTC 	;check for ^C, if so print error message, warm start BASIC
  
  lda found_eol
  bne @got_eol  
  lda #75
  jsr $fca8 ;wait for about 15ms - this gives a total timeout of ~4seconds
  inc polling_counter
  bne @main_polling_loop
  jmp @listen
  
@got_eol:

  jsr reset_output_buffer

  ldy #$FF
:
  iny
  lda status_ok,y
  sta status_code_buffer,y
  bne :-
  
  ldy #$FF
:
  iny
  lda text_html,y
  sta content_type_buffer,y
  bne :-

  sta sent_header
  
  ldax httpd_io_buffer  
  jmp got_http_request

http_callback: 
  lda tcp_inbound_data_length+1
  cmp #$ff
  bne @not_eof
  inc connection_closed
@done:
  rts
@not_eof:
  lda found_eol
  bne @done
  
;copy this chunk to our input buffer
  ldax tcp_buffer_ptr 
  stax copy_dest
  ldax tcp_inbound_data_ptr
  stax copy_src
  ldax tcp_inbound_data_length
  jsr copymem
  
;increment the pointer into the input buffer  
  clc
  lda tcp_buffer_ptr  
  adc tcp_inbound_data_length
  sta tcp_buffer_ptr
  sta copy_src
  lda tcp_buffer_ptr+1
  adc tcp_inbound_data_length+1
  sta tcp_buffer_ptr+1  
  sta copy_src+1
  
;put a null byte at the end (assumes we have set copy_src already)
  lda #0
  tay
  sta (copy_src),y
    
;look for CR or LF in input
  sta found_eol
  ldax httpd_io_buffer
  stax get_next_byte+1

@look_for_eol:
  jsr get_next_byte
  cmp #$0a
  beq @found_eol    
  cmp #$0d
  bne @not_eol
@found_eol:
  inc found_eol
  rts
@not_eol:
  cmp #0
  bne @look_for_eol 
  rts
  
  

reset_output_buffer:
  ldax httpd_io_buffer  
  sta xmit_a_ptr+1
  stx xmit_a_ptr+2
  lda #0
  sta output_buffer_length
  sta output_buffer_length+1 
  rts

        
send_buffer:    
  ldax output_buffer_length
  stax tcp_send_data_len
  ldax httpd_io_buffer  
  jsr tcp_send
  jmp reset_output_buffer
 

emit_string:
	stax	copy_src
	ldy	#0
@next_byte:
	lda	(copy_src),y
	beq	@done
	jsr	xmit_a
	iny
	bne	@next_byte
@done:
	rts

got_http_request:
  jsr http_parse_request  
  ldax #path
  jsr print
  lda #$02
  jsr http_get_value
  stax copy_src
  jsr print
  jsr print_cr
  
  ;now restore stack to how it was when &HTTPD was called, and return to BASIC
  ldx top_of_stack	
  txs
  rts


bang_handler:
	jsr extract_string
	lda sent_header
	bne :+
	jsr send_header
:  
	ldy #0
	sty	string_ptr
@loop:
	lda transfer_buffer,y
	jsr	xmit_a
	inc string_ptr
	ldy string_ptr
	cpy param_length
	bne	@loop
	rts

send_header:
	inc sent_header
	ldax	#http_version
	jsr	emit_string
	ldax	#status_code_buffer
	jsr	emit_string
	ldax #crlf
	jsr	emit_string
	ldax	#content_type
	jsr	emit_string
	ldax #content_type_buffer
	jsr	emit_string  
	ldax 	#end_of_header
	jmp	emit_string			

flush_handler:  
	lda output_buffer_length
	bne :+
	ldx output_buffer_length+1
	bne :+
	rts
:  
	jmp send_buffer

.rodata	
keyword_table:
.byte "IPCFG",0
.word ipcfg_handler-1
.byte "DHCP",0
.word dhcp_handler-1
.byte "PING",0
.word ping_handler-1
.byte "MYIP",0
.word myip_handler-1
.byte "DNS",0
.word dns_handler-1
.byte "G",$c5,"EWAY",0	;$C5 is token for 'AT'
.word gateway_handler-1
.byte "NETMASK",0
.word netmask_handler-1
.byte "HTTPD",0
.word httpd_handler-1
.byte "!",0
.word bang_handler-1
.byte "FLUSH",0
.word flush_handler-1

.byte $ff

keyword_table_size=*-keyword_table
.if     keyword_table_size>255
        .error  "KEYWORD TABLE TOO BIG!"
.endif
  
CR=$0D
LF=$0A
  
dhcp:
.byte "DHCP",0
address_resolution:
.byte "ADDRESS RESOLUTION",0
error:
.byte " ERROR $",0
pinging:
.byte "PINGING ",0

path:
 .byte "PATH: ",0
http_version:		
	.byte "HTTP/1.0 ",0

status_ok:
	.byte "200 OK",0
status_error:
		.byte "500 "
system_error:    
    .byte "SYSTEM ERROR",0
content_type:
	.byte "Content-Type: ",0
text_html:
	.byte "text/html",0
	
end_of_header:
  .byte CR,LF
	.byte "Connection: Close",CR,LF
	.byte "Server: AppleSoft.NET/0.2",CR,LF
crlf:  
	.byte CR,LF,0
	
connection_from: .byte "CONNECTION FROM ",0
chain_cmd:

.byte 13,4,"RUN AUTOEXEC.BAS",13,0
 
listening:
.byte"LISTENING ON ",0


 
.data


httpd_io_buffer: .word __httpd_io_buffer  
httpd_port_number: .word 80


get_next_byte:
  lda $ffff
  inc get_next_byte+1
  bne @skip
  inc get_next_byte+2
@skip:
  rts

  
xmit_a:
  
xmit_a_ptr:
  sta $ffff
  inc xmit_a_ptr+1
  bne :+
  inc xmit_a_ptr+2
:
  inc output_buffer_length
  bne :+
  inc output_buffer_length+1
  lda output_buffer_length+1
  cmp #2
  bne :+
  stx temp_x
  jsr send_buffer    
  ldx temp_x
:    
  rts

.bss 
  
transfer_buffer: .res 256
param_length: .res 1
ping_counter: .res 1
handler_address: .res 2
temp_x: .res 1
output_buffer_length: .res 2
sent_header: .res 1
content_type_buffer: .res 128
status_code_buffer: .res 128
found_eol: .byte 0
connection_closed: .byte 0
tcp_buffer_ptr: .res 2
top_of_stack: .res 1
polling_counter: .res 1
string_ptr: .res 1
__httpd_io_buffer: .res 1024 ;temp buffer for storing inbound requests.

