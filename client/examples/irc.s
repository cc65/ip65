
.include "../inc/common.i"

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

print_a = $ffd2

.import ascii_to_native

.macro  kippercall function_number
  ldy function_number
  jsr KPR_DISPATCH_VECTOR   
.endmacro

.zeropage
temp_buff: .res 2
pptr: .res 2

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

init:

  .import cls
  jsr cls
  lda #14
  jsr print_a ;switch to lower case  
  
  ldax #KPR_CART_SIGNATURE  ;where signature should be in cartridge (if cart is banked in)
look_for_signature:
  stax temp_buff
  ldy #5
@check_one_byte:
  lda (temp_buff),y
  cmp kipper_signature,y
  bne @bad_match  
  dey 
  bpl @check_one_byte  
  jmp @found_kipper_signature
  
@bad_match:
  ldax #kipper_api_not_found_message
  jsr print
  rts
@found_kipper_signature:
  ldax #init_msg
  jsr print
  kippercall #KPR_INITIALIZE
	bcc @init_ok
  jsr print_cr
  ldax #failed_msg
  jsr print
  jsr print_cr
  jsr print_errorcode
  jmp reset_after_keypress    
@init_ok:
;if we got here, we have found the KIPPER API and initialised the IP stack  
  jsr print_ok  
  jsr print_cr
  ldax #connecting_msg
  jsr print
  jsr connect_to_irc
  bcc @connect_ok
  jsr print_errorcode  
  jmp reset_after_keypress    
@connect_ok:

  jsr print_ok
  jsr print_cr
  jsr send_nick
  jsr send_user
  jsr send_join

@endless_loop:
  jsr KPR_PERIODIC_PROCESSING_VECTOR
	jmp	@endless_loop
	
print_ok:
ldax #ok_msg
jmp print

reset_after_keypress:
  ldax #press_a_key_to_continue    
  jsr print
@wait_key:
  jsr $f142 ;not officially documented - where F13E (GETIN) falls through to if device # is 0 (KEYBD)
  beq @wait_key
  jmp $fce2   ;do a cold start

print_errorcode:
  ldax #error_code
  jsr print
  kippercall #KPR_GET_LAST_ERROR
  kippercall #KPR_PRINT_HEX
  jmp print_cr


print:
	sta pptr
	stx pptr + 1
	
@print_loop:
  ldy #0
  lda (pptr),y
	beq @done_print
	jsr print_a
	inc pptr
	bne @print_loop
  inc pptr+1
  bne @print_loop ;if we ever get to $ffff, we've probably gone far enough ;-)
@done_print:
  rts

print_cr:
  lda #13
  jmp print_a


connect_to_irc:
  ldax #irc_server
  stax param_buffer
  ldax #param_buffer
  kippercall #KPR_DNS_RESOLVE
  bcs @exit
  
  ;IP address now set
  ldax irc_port
  stax param_buffer+KPR_TCP_PORT
  ldax #irc_callback
  stax param_buffer+KPR_TCP_CALLBACK
  ldax #param_buffer
  kippercall #KPR_TCP_CONNECT

@exit:  
  rts

send_nick:
  ldx #0
:  
  lda nick_msg,x
  beq :+
  sta command_buffer,x
  inx
  bne :-
:  
  ldy #0
:  
  lda nick,y
  beq :+
  sta command_buffer,x  
  iny
  inx
  bne :-
:
  
add_crlf_and_send_command:  
  lda #13
  sta command_buffer,x  
  inx
  lda #10
  sta command_buffer,x  
  inx
  txa
  ldx #0
  stax param_buffer+KPR_TCP_PAYLOAD_LENGTH
  ldax #command_buffer
  stax param_buffer+KPR_TCP_PAYLOAD_POINTER
  ldax #param_buffer
  kippercall #KPR_SEND_TCP_PACKET
  rts

send_user:
  ldax #user_msg_length
  stax param_buffer+KPR_TCP_PAYLOAD_LENGTH
  ldax #user_msg
  stax param_buffer+KPR_TCP_PAYLOAD_POINTER
  ldax #param_buffer
  kippercall #KPR_SEND_TCP_PACKET
  rts

send_join:
  ldx #0
:  
  lda join_msg,x
  beq :+
  sta command_buffer,x
  inx
  bne :-
:  
  ldy #0
:  
  lda irc_channel,y
  beq :+
  sta command_buffer,x  
  iny
  inx
  bne :-
:
  
  jmp add_crlf_and_send_command  
  
irc_callback:
  ldax #param_buffer
  kippercall #KPR_GET_INPUT_PACKET_INFO  
  lda param_buffer+KPR_PAYLOAD_LENGTH+1
  cmp #$ff
  bne @not_eof
  rts
@not_eof:
  ldax param_buffer+KPR_PAYLOAD_POINTER
  stax pptr
  ldax param_buffer+KPR_PAYLOAD_LENGTH
  stax input_length
: 

@print_loop:
  ldy #0
  lda (pptr),y
  jsr ascii_to_native
	jsr print_a
  dec input_length
  lda input_length
  cmp #$ff
  bne :+
  dec input_length+1
  lda input_length
  cmp #$ff
  beq @done_print
:
	inc pptr
	bne @print_loop
  inc pptr+1
  bne @print_loop ;if we ever get to $ffff, we've probably gone far enough ;-)
@done_print:
  rts
  
.bss
param_buffer: .res 20
command_buffer: .res 256
input_length: .res 2

.data

irc_server:
 ;.byte "irc.newnet.net",0
  .byte "jamtronix.com",0
irc_port:
  .word   6667
irc_channel: 
  .byte "#foo",0


nick_msg:
  .byte "NICK ",0

nick:
  .byte "kipper_nick2",0

join_msg:
  .byte "JOIN ",0

user_msg:
  .byte "USER kipper 0 unused :A Kipper User",13,10
user_msg_length=*-user_msg

kipper_api_not_found_message:
  .byte "ERROR - KIPPER API NOT FOUND.",13,0

failed_msg:
	.byte "FAILED", 0

ok_msg:
	.byte "OK", 0
init_msg:
  .byte "INITIALIZING ",0
 connecting_msg:
  .byte "CONNECTING ",0
  
press_a_key_to_continue:
  .byte "PRESS A KEY TO CONTINUE",13,0

kipper_signature:
.byte $4B,$49,$50,$50,$45,$52 ; "KIPPER"

error_code:  
  .asciiz "ERROR CODE: "




;-- LICENSE FOR irc.s --
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
