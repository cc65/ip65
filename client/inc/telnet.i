;telnet routines
; to use:
; 1) include this file 
; 2) include these other files:
;  .include "../inc/common.i"
;  .include "../inc/commonprint.i"
;  .include "../inc/net.i"
;  .include "../inc/char_conv.i"
;  .include "../inc/c64keycodes.i"
; 3) define a routine called 'exit_telnet'
; 4) define a buffer called 'scratch_buffer'
; 5) define a zero page var called buffer_ptr
.code
telnet_main_entry:
;prompt for a hostname, then resolve to an IP address
  
  ldax #remote_host
  jsr print
  nb65call #NB65_INPUT_HOSTNAME
  bcc @host_entered
  ;if no host entered, then bail.
  jmp exit_telnet
@host_entered:
  stax nb65_param_buffer
  jsr print_cr
  ldax #resolving
  jsr print
  ldax nb65_param_buffer
  nb65call #NB65_PRINT_ASCIIZ
  jsr print_cr
  ldax #nb65_param_buffer
  nb65call #NB65_DNS_RESOLVE
  bcc @resolved_ok
  print_failed
  jsr print_cr
  jsr print_errorcode
  jmp telnet_main_entry
@resolved_ok:
  ldx #3
@copy_telnet_ip_loop:
  lda nb65_param_buffer,x
  sta telnet_ip,x
  dex
  bpl @copy_telnet_ip_loop
@get_port:
  ldax #remote_port
  jsr print
  nb65call #NB65_INPUT_PORT_NUMBER
  bcc @port_entered
  ;if no port entered, then assume port 23
  ldax #23
@port_entered:
  stax telnet_port
  jsr print_cr
  
  ldax #char_mode_prompt
  jsr print
@char_mode_input:
  jsr get_key
  cmp #'A'
  beq @ascii_mode
  cmp #'a'
  beq @ascii_mode

  cmp #'P'
  beq @petscii_mode
  cmp #'p'
  beq @petscii_mode
  jmp @char_mode_input
@ascii_mode:
  lda #0
  sta character_set
  sta line_mode
  lda #1
  sta local_echo
  lda #telnet_state_normal
  sta telnet_state
  jmp @after_mode_set
@petscii_mode:
  lda #1
  sta character_set
  lda #0
  sta local_echo
  sta line_mode

  
@after_mode_set:
  
  lda #147  ; 'CLR/HOME'
  jsr print_a
  
  ldax  #connecting_in
  jsr print
  lda  character_set
  beq @a_mode
  ldax #petscii
  jsr print
  jmp @c_mode
@a_mode:
  ldax #ascii
  jsr print
@c_mode:
  ldax #mode
  jsr print
  
telnet_connect:
  ldax #telnet_callback
  stax nb65_param_buffer+NB65_TCP_CALLBACK
  ldx #3
@copy_dest_ip:
  lda telnet_ip,x
  sta nb65_param_buffer+NB65_TCP_REMOTE_IP,x
  dex  
  bpl @copy_dest_ip
  ldax telnet_port
  stax nb65_param_buffer+NB65_TCP_PORT
  ldax #nb65_param_buffer
  nb65call #NB65_TCP_CONNECT

  bcc @connect_ok 
  jsr print_cr
  print_failed
  jsr print_errorcode
  jmp telnet_main_entry
@connect_ok:
  print_ok
  jsr print_cr
  lda #0
  sta connection_closed
@main_polling_loop:
  jsr NB65_PERIODIC_PROCESSING_VECTOR
  lda connection_closed
  beq @not_disconnected
  ldax #disconnected
  jsr print
  jmp telnet_main_entry
@not_disconnected:
  lda line_mode  
  beq @not_line_mode
  
  nb65call #NB65_INPUT_STRING
  stax buffer_ptr
  ldy #0
@copy_one_char:
  lda (buffer_ptr),y
  tax
  lda petscii_to_ascii_table,x
  beq @end_of_input_string
  sta scratch_buffer,y
  iny 
  bne @copy_one_char
@end_of_input_string:
  lda #$0d
  sta scratch_buffer,y
  iny 
  lda #$0a
  sta scratch_buffer,y
  iny 
  sty nb65_param_buffer+NB65_TCP_PAYLOAD_LENGTH
  lda #0
  sta nb65_param_buffer+NB65_TCP_PAYLOAD_LENGTH+1
  
  jmp @no_more_input
  
@not_line_mode:  
  
  ;is there anything in the input buffer?
  lda $c6 ;NDX - chars in keyboard buffer
  beq @main_polling_loop
  lda #0
  sta nb65_param_buffer+NB65_TCP_PAYLOAD_LENGTH
  sta nb65_param_buffer+NB65_TCP_PAYLOAD_LENGTH+1
@get_next_char:
  jsr $ffe4 ;getkey - 0 means no input
;  pha
;  jsr print_hex
;  pla
  tax  
  beq @no_more_input
  cmp #$03 ;RUN/STOP
  bne @not_runstop
  lda  #0
  sta $cb ;overwrite "current key pressed" else it's seen by the tcp stack and the close aborts

  ldax #closing_connection
  jsr print
  nb65call  #NB65_TCP_CLOSE_CONNECTION
  bcs @error_on_disconnect
  ldax #disconnected
  jsr print
  jmp telnet_main_entry
@error_on_disconnect:
  jsr print_errorcode
  jsr print_cr
  jmp telnet_main_entry
@not_runstop:  
  lda character_set
  bne @no_conversion_required
  txa
  cmp #$0d
  bne @not_cr
  
  ;if we get a CR in ascii mode, send CR/LF
  ldy nb65_param_buffer+NB65_TCP_PAYLOAD_LENGTH
  sta scratch_buffer,y
  inc nb65_param_buffer+NB65_TCP_PAYLOAD_LENGTH
  ldx #$0a
  jmp @no_conversion_required
@not_cr:  
  lda petscii_to_ascii_table,x
  tax
@no_conversion_required:
  txa
  ldy nb65_param_buffer+NB65_TCP_PAYLOAD_LENGTH
  sta scratch_buffer,y
  inc nb65_param_buffer+NB65_TCP_PAYLOAD_LENGTH
  jmp @get_next_char
@no_more_input:
  ldax  #scratch_buffer
  stax nb65_param_buffer+NB65_TCP_PAYLOAD_POINTER
  ldax  #nb65_param_buffer
  nb65call  #NB65_SEND_TCP_PACKET
  bcs @error_on_send
  jmp @main_polling_loop

@error_on_send:
  ldax #transmission_error
  jsr print
  jsr print_errorcode
  jmp telnet_main_entry

;tcp callback - will be executed whenever data arrives on the TCP connection
telnet_callback:
  ldax #nb65_param_buffer
  nb65call #NB65_GET_INPUT_PACKET_INFO
  
  lda nb65_param_buffer+NB65_PAYLOAD_LENGTH+1
  cmp #$ff
  bne @not_eof
  lda #1
  sta connection_closed
  rts
@not_eof:
  
  ldax nb65_param_buffer+NB65_PAYLOAD_POINTER
  stax buffer_ptr
  lda nb65_param_buffer+NB65_PAYLOAD_LENGTH 
  sta buffer_length
  lda nb65_param_buffer+NB65_PAYLOAD_LENGTH+1
  sta buffer_length+1
  dec buffer_length 
  bpl :+
   dec buffer_length+1
:  
  ldy #0
  sty iac_response_buffer_length
@next_byte:
  lda (buffer_ptr),y
  tax
  lda character_set
  beq :+
  jmp  @no_conversion_req
:

  lda telnet_state
  cmp #telnet_state_got_command
  beq @waiting_for_option
  cmp #telnet_state_got_iac
  beq @waiting_for_command
; we must be in 'normal' mode
  txa
  cmp #255
  beq :+
  jmp @not_iac
:  
  lda #telnet_state_got_iac
  sta telnet_state
  jmp @byte_processed
@waiting_for_command:
  txa
  sta telnet_command
  cmp #$fb ;WILL 
  beq @option
  cmp #$fc ;WONT
  beq @option
  cmp #$fd ; DO
  beq @option
  cmp #$fe ;DONT
  beq @option
;we got a command we don't understand - just ignore it  
  lda #telnet_state_normal  
  sta telnet_state
  jmp @byte_processed
@option:
  lda #telnet_state_got_command
  sta telnet_state
  jmp @byte_processed

@waiting_for_option:
;we have now got IAC, <command>, <option>
  txa 
  sta telnet_option  
  lda telnet_command
  
  cmp #$fb
  beq @iac_will

  cmp #$fc
  beq @iac_wont

  ;if we get here, then it's a "do" or "don't", both of which we should send a "wont" back for
  ;(since there are no "do" options we actually honour)
  lda #$fc ;wont
@add_iac_response:  
  ldx iac_response_buffer_length
  sta iac_response_buffer+1,x
  lda #255
  sta iac_response_buffer,x
  lda telnet_option
  sta iac_response_buffer+2,x

  inc iac_response_buffer_length
  inc iac_response_buffer_length
  inc iac_response_buffer_length
  
  lda #telnet_state_normal
  sta telnet_state
  jmp @byte_processed
@iac_will:
  lda telnet_option
  cmp #$01 ;ECHO
  beq @will_echo  
  cmp #$03 ;DO SUPPRESS GA
  beq @will_suppress_ga

@iac_wont:  
  lda #$fe ;dont
  jmp @add_iac_response
  
@will_echo:
  lda #0
  sta local_echo
  lda #$fd ;DO
  jmp @add_iac_response
  
@will_suppress_ga:
  lda #0
  sta line_mode
  lda #$fd ;DO
  jmp @add_iac_response

@not_iac:

  lda ascii_to_petscii_table,x
  tax
@no_conversion_req:
  tya
  pha
  txa  
  jsr print_a
  pla
  tay
@byte_processed:  
  iny
  dec buffer_length
  lda #$ff
  cmp buffer_length
  beq :+
  jmp @next_byte
:  
  inc buffer_ptr+1
  dec buffer_length+1
  bmi @finished
  ldy #0
  jmp @next_byte
@finished:  
  
  lda iac_response_buffer_length  
  beq @no_iac_response
  ldx #0
  stax nb65_param_buffer+NB65_TCP_PAYLOAD_LENGTH
  ldax  #iac_response_buffer
  stax nb65_param_buffer+NB65_TCP_PAYLOAD_POINTER
  ldax  #nb65_param_buffer
  nb65call  #NB65_SEND_TCP_PACKET
@no_iac_response:
  rts
  
;constants
closing_connection: .byte "CLOSING CONNECTION",13,0
connecting_in: .byte "CONNECTING IN ",0

ascii: .byte "ASCII",0
petscii: .byte "PETSCII",0
mode: .byte " MODE",13,0
disconnected: .byte 13,"CONNECTION CLOSED",13,0
remote_host: .byte "HOSTNAME (LEAVE BLANK TO QUIT)",13,": ",0
remote_port: .byte "PORT # (LEAVE BLANK FOR DEFAULT)",13,": ",0
char_mode_prompt: .byte "CHARACTER MODE - A=ASCII, P=PETSCII",13,0
transmission_error: .byte "ERROR WHILE SENDING ",0

;variables
.segment "APP_SCRATCH" 
telnet_ip:  .res 4
telnet_port: .res 2

connection_closed: .res 1
character_set: .res 1
buffer_offset: .res 1
local_echo: .res 1
line_mode: .res 1
telnet_state: .res 1
telnet_command: .res 1
telnet_option: .res 1

telnet_state_normal = 0
telnet_state_got_iac = 1
telnet_state_got_command = 2

;nb65_param_buffer DS.B $20  
buffer_length: .res 2

iac_response_buffer: .res 256
iac_response_buffer_length: .res 1