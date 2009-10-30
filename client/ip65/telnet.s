;minimal telnet implementation (dumb terminal emulation only)
;to use:
;set the following variables - telnet_local_echo, telnet_line_mode,telnet_use_native_charset,telnet_port,telnet_ip
;then call telnet_connect
;sensible combinations of telnet_local_echo, telnet_line_mode,telnet_use_native_charset are:
;for interacting with 'line at time' servers (smtp/pop3/http/gopher): telnet_local_echo=1, telnet_line_mode=1,telnet_use_native_charset=0
;for logging in to a normal telnet server:  telnet_local_echo=0, telnet_line_mode=0,telnet_use_native_charset=0
;for logging in to a PETSCII BBS on a C64 : telnet_local_echo=0, telnet_line_mode=0,telnet_use_native_charset=1


.include "../inc/common.i"

  .import tcp_connect
  .import tcp_callback
  .import tcp_connect_ip
  .import tcp_listen
  .importzp KEYCODE_ABORT
  .import tcp_inbound_data_ptr
  .import tcp_inbound_data_length
  .import tcp_send
  .import tcp_send_data_len
  .import tcp_close
  .import print_a
  .import print_cr
  .import vt100_init_terminal
  .import vt100_process_inbound_char
  .import vt100_transform_outbound_char


  .import ip65_process
  .import get_key_ip65
  .import get_filtered_input
  .import ok_msg
  .import failed_msg
  .import print
  .import print_errorcode
  .import native_to_ascii
  .import ascii_to_native

.export telnet_connect
.export telnet_local_echo
.export telnet_line_mode
.export telnet_use_native_charset
.export telnet_port
.export telnet_ip

.segment "IP65ZP" : zeropage

; pointer for moving through buffers
buffer_ptr:	.res 2			; source pointer

.code
telnet_connect:
  lda telnet_use_native_charset
  beq :+
  jsr vt100_init_terminal
:  
  ldax #telnet_callback
  stax tcp_callback
  ldx #3
@copy_dest_ip:
  lda telnet_ip,x
  sta tcp_connect_ip,x
  dex  
  bpl @copy_dest_ip
  
  ldax telnet_port
  jsr tcp_connect

  bcc @connect_ok 
  jsr print_cr
  ldax #failed_msg
  jsr print
  jsr print_errorcode
  rts
@connect_ok:
  ldax #ok_msg
  jsr print
  jsr print_cr
  lda #0
  sta connection_closed
@main_polling_loop:
  jsr ip65_process
  lda connection_closed
  beq @not_disconnected
  ldax #disconnected
  jsr print
  rts
@not_disconnected:
  lda telnet_line_mode  
  beq @not_line_mode
  
  ldy #40 ;max chars
  ldax #$0000
  jsr get_filtered_input
  stax buffer_ptr
  ldy #0
@copy_one_char:
  lda (buffer_ptr),y
  jsr native_to_ascii
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
  sty tcp_send_data_len
  lda #0
  sta tcp_send_data_len+1
  jsr print_cr  
  jmp @send_char
  
@not_line_mode:  
  
  jsr get_key_ip65  
  tax  
;  beq @send_char
  cmp #KEYCODE_ABORT
  bne @not_abort

  ldax #closing_connection
  jsr print
  jsr tcp_close
  bcs @error_on_disconnect
  ldax #disconnected
  jsr print
  rts
@error_on_disconnect:
  jsr print_errorcode
  jsr print_cr
  rts
@not_abort:
  lda #0
  sta tcp_send_data_len
  sta tcp_send_data_len+1

  lda telnet_use_native_charset
  bne @no_conversion_required
  txa
  cmp #$0d
  bne @not_cr
  
  ;if we get a CR in ascii mode, send CR/LF
  ldy tcp_send_data_len
  sta scratch_buffer,y
  inc tcp_send_data_len
  ldx #$0a
  jmp @no_conversion_required
@not_cr:
  txa
  jsr native_to_ascii  
  tax
@no_conversion_required:
  txa
  ldy tcp_send_data_len
  sta scratch_buffer,y
  inc tcp_send_data_len
@send_char:
  ldax  #scratch_buffer
  jsr tcp_send
  bcs @error_on_send
  jmp @main_polling_loop

@error_on_send:
  ldax #transmission_error
  jsr print
  jsr print_errorcode
  rts

;tcp callback - will be executed whenever data arrives on the TCP connection
telnet_callback:
  
  lda tcp_inbound_data_length+1
  cmp #$ff
  bne @not_eof
  lda #1
  sta connection_closed
  rts
@not_eof:
  
  ldax tcp_inbound_data_ptr
  stax buffer_ptr
  lda tcp_inbound_data_length
  sta buffer_length
  lda tcp_inbound_data_length+1
  sta buffer_length+1
  
  ;since we don't check the buffer length till the end of the loop, set 'buffer length' to be 1 less than the actual number of bytes
  dec buffer_length 
  bpl :+
   dec buffer_length+1
:  
  ldy #0
  sty iac_response_buffer_length
@next_byte:
  lda (buffer_ptr),y
  tax
  lda telnet_use_native_charset
  beq :+
  jmp  @no_conversion_req
:

  lda telnet_line_mode
  beq :+ 
  jmp@convert_to_native
:  
;if we get here, we are in ASCII 'char at a time' mode,  so look for (and process) Telnet style IAC bytes
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
  sta telnet_local_echo
  lda #$fd ;DO
  jmp @add_iac_response
  
@will_suppress_ga:
  lda #0
  sta telnet_line_mode
  lda #$fd ;DO
  jmp @add_iac_response

@not_iac:
@convert_to_native:
  txa
  cmp #$0a  ;suppress LF (since it probably follows a CR which will have done the LF as well)
  beq @byte_processed
  jsr ascii_to_native
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
  bne :+
  inc buffer_ptr+1
:  
  dec buffer_length
  lda #$ff
  cmp buffer_length
  beq :+
  jmp @next_byte
:  
  
  dec buffer_length+1
  bmi @finished
  jmp @next_byte
@finished:  
  
  lda iac_response_buffer_length  
  beq @no_iac_response
  ldx #0
  stax tcp_send_data_len
  ldax  #iac_response_buffer
  jsr tcp_send
@no_iac_response:
  rts
  
;constants
closing_connection: .byte "CLOSING CONNECTION",13,0
disconnected: .byte 13,"CONNECTION CLOSED",13,0
transmission_error: .byte "ERROR WHILE SENDING ",0

;variables
.segment "APP_SCRATCH" 
telnet_ip:  .res 4  ;ip address of remote server
telnet_port: .res 2 ;port number to connect to

connection_closed: .res 1
telnet_use_native_charset: .res 1 ; 0 means all data is translated to/from NVT ASCII 
buffer_offset: .res 1
telnet_local_echo: .res 1   ;0 should mean local echo is disabled - in fact at the moment we never do local echo except in 'line mode'
telnet_line_mode: .res 1 ;do characters get sent after each keypress, or can a line be created/edited and then sent only when return is pressed?
telnet_state: .res 1
telnet_command: .res 1
telnet_option: .res 1

telnet_state_normal = 0
telnet_state_got_iac = 1
telnet_state_got_command = 2

buffer_length: .res 2

iac_response_buffer: .res 64
iac_response_buffer_length: .res 1
scratch_buffer : .res 40


;-- LICENSE FOR telnet.s --
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
