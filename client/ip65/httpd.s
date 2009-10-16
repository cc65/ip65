;a simple HTTP server
;to use - call httpd_start with AX pointing at routine to call for each inbound page
;call httpd_stop to exit gracefully.
.include "../inc/common.i"

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif


HTTPD_TIMEOUT_SECONDS=5 ;what's the maximum time we let 1 connection be open for?

.export httpd_start

.import http_parse_request
.import http_get_value
.import tcp_listen
.import tcp_callback
.import ip65_process
.import check_for_abort_key
.import ip65_error
.import print
.import copymem
.importzp copy_src
.importzp copy_dest
.import tcp_inbound_data_ptr
.import tcp_inbound_data_length
.import tcp_send_data_len
.import tcp_send
.import tcp_close

temp_ptr =copy_src

.segment "HTTP_VARS"
tcp_buffer_ptr: .res 2
httpd_buffer: .word $2000 ;by default, use a buffer at $2000 for storing inbound requests.
httpd_port_number: .word 80
connection_timeout_seconds: .byte 0
found_eol: .byte 0
connection_closed: .byte 0
output_buffer_length: .res 2

jump_to_callback:
  jmp $ffff

get_next_byte:
  lda $ffff
  inc get_next_byte+1
  bne @skip
  inc get_next_byte+2
@skip:
  rts

  
emit_a:
  sta $ffff
  inc emit_a+1
  bne :+
  inc emit_a+2
:
  inc output_buffer_length
  bne :+
  inc output_buffer_length+1
  lda output_buffer_length+1
  cmp #2
  bne :+
  jmp send_buffer  
:  
  rts

.code

;start a HTTP server
;this routine will stay in an endless loop that is broken only if user press the ABORT key (runstop on a c64)
;inputs: 
;httpd_port_number=port number to listen on
;AX = pointer to routine to callback for each inbound HTTP request=
;set this to $0000 to use the default handler (which will look for requested files on the local disk).
;outputs:
; none
httpd_start:
  stx jump_to_callback+2
  bne @not_default_handler
  ldax #default_httpd_handler
  jmp httpd_start
@not_default_handler:
  sta jump_to_callback+1
  
@listen:
  jsr tcp_close
  ldax httpd_buffer
  stax tcp_buffer_ptr 
  ldax #http_callback
  stax tcp_callback
  ldax httpd_port_number
  
  jsr tcp_listen
  bcc @connect_ok
  rts 
@connect_ok: 
  lda #0
  sta connection_closed
  sta found_eol
  clc
  lda $dc09  ;time of day clock: seconds (in BCD)
  sed
  adc #HTTPD_TIMEOUT_SECONDS
  cmp #$60
  bcc @timeout_set
  sec
  sbc #$60
@timeout_set:  
  cld
  sta connection_timeout_seconds

@main_polling_loop:
  jsr ip65_process
  jsr check_for_abort_key
  bcc @no_abort
  lda #KPR_ERROR_ABORTED_BY_USER
  sta ip65_error
  rts
@no_abort:  
  lda found_eol
  bne @got_eol  

  lda $dc09  ;time of day clock: seconds
  
  cmp connection_timeout_seconds  
  beq @connection_timed_out
  lda connection_closed
  beq  @main_polling_loop  
@connection_timed_out:
  jmp @listen
  
@got_eol:
  ldax httpd_buffer  
  jsr http_parse_request
  jsr jump_to_callback  ;call the handler to generate the response for this request.
  ;AX should now point at data to be sent
  ;Y should contain the content type/status code
  bcs :+    ;carry is set if the callback routine already sent the response
  jsr send_response
  :
  
  jmp @listen ;go listen for the next request
  

http_callback:  
  lda tcp_inbound_data_length+1
  cmp #$ff
  bne @not_eof
  inc connection_closed
  rts
@not_eof:
  
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
  sta temp_ptr
  lda tcp_buffer_ptr+1
  adc tcp_inbound_data_length+1
  sta tcp_buffer_ptr+1  
  sta temp_ptr+1
  
;put a null byte at the end (assumes we have set temp_ptr already)
  lda #0
  tay
  sta (temp_ptr),y
    
;look for CR or LF in input
  sta found_eol
  ldax httpd_buffer
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
  
  
default_httpd_handler:
  lda #$02
  jsr http_get_value
  bcc @not_error
  ldy #5
  clc
  rts
@not_error:  
  stax temp_ptr
  ldy #1
  lda (temp_ptr),y
  bne @not_index
  ldax #default_html
  ldy #2
  clc
  rts
@not_index:
  ldy #4
  clc
  rts

send_response:
  stax get_next_byte+1
  jsr reset_output_buffer
  jsr send_header  
  
@response_loop:
  jsr get_next_byte
  cmp #0
  beq send_buffer
  jsr emit_a
  jmp @response_loop
  
  
reset_output_buffer:
  ldax httpd_buffer  
  sta emit_a+1
  stx emit_a+2
  lda #0
  sta output_buffer_length
  sta output_buffer_length+1
  rts
  
send_buffer:    
  ldax output_buffer_length
  stax tcp_send_data_len
  ldax httpd_buffer  
  jsr tcp_send
  jmp reset_output_buffer
 
 send_header:
;inputs: Y = header type
;$00 = no header (assume header sent already)
;$01 = 200 OK, 'text/text'
;$02 = 200 OK, 'text/html'
;$03 = 200 OK, 'application/octet-stream' 
;$04 = 404 Not Found
;$05..$FF = 500 System Error

	cpy #00
	bne :+
	rts
:
	cpy #1
	bne	@not_text
	jsr	emit_ok_status_line_and_content_type
	ldax	#text_text
	jsr	emit_string
	jmp	@done

@not_text:
	cpy #2
  
	bne	@not_html
	jsr	emit_ok_status_line_and_content_type
	ldax	#text_html
	jsr	emit_string
	jmp	@done

@not_html:
	cpy #3
	bne	@not_binary
	jsr	emit_ok_status_line_and_content_type
	ldax	#application_octet_stream
	jsr	emit_string
	jmp	@done

@not_binary:
	cpy #4
	bne	@not_404
	ldax	#http_version
	jsr	emit_string
	ldax	#status_not_found
	jsr	emit_string

	jsr @done
  ldax #status_not_found
  jmp emit_string
  
@not_404:
	ldax	#http_version
	jsr	emit_string
	ldax	#status_system_error
	jsr	emit_string
	jsr @done
  ldax #status_system_error
  jmp emit_string
@done:
	ldax 	#end_of_header
	jmp	emit_string			


emit_ok_status_line_and_content_type:
	ldax	#http_version
	jsr	emit_string
	ldax	#status_ok
	jsr	emit_string
	ldax	#content_type
	jmp	emit_string		

emit_string:
	stax	temp_ptr
	ldy	#0
@next_byte:
	lda	(temp_ptr),y
	beq	@done
	jsr	emit_a
	iny
	bne	@next_byte
@done:
	rts
	
 
.rodata
default_html:
.byte "<h1>w00t!</h1><br>yadda yadda yadd!"
.byte 0


CR=$0D
LF=$0A

http_version:		
	.byte "HTTP/1.0 ",0

status_ok:
	.byte "200 OK",CR,LF,0

status_not_found:
	.byte "404 Not Found",CR,LF,0

status_system_error:
	.byte "500 System Error",CR,LF,0
content_type:
	.byte "Content-Type: ",0

text_text:
	.byte "text/text",CR,LF,0

text_html:
	.byte "text/html",CR,LF,0
	
application_octet_stream:
	.byte "application/octet-stream",CR,LF,0

end_of_header:
	.byte "Connection: Close",CR,LF
	.byte "Server: Kipper_httpd/0.c64",CR,LF
	.byte CR,LF,0
