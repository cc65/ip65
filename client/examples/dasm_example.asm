;NB65 API example in DASM format (http://www.atari2600.org/DASM/)
  processor 6502

  include "../inc/nb65_constants.i"

  ;useful macros 
  mac     ldax
    lda     [{1}]
    ldx     [{1}]+1
  endm

  mac     ldaxi
    lda     #<[{1}]
    ldx     #>[{1}]
  endm

  mac     stax
    sta     [{1}]
    stx     [{1}]+1
  endm

  mac cout
    lda [{1}]
    jsr print_a
  endm   

  mac print_cr
    cout #13
    jsr print_a
  endm

  mac nb65call
    ldy [{1}]
    jsr NB65_DISPATCH_VECTOR   
  endm

  mac print
    
    ldaxi [{1}]
    ldy #NB65_PRINT_ASCIIZ
    jsr NB65_DISPATCH_VECTOR   
  endm


;some routines & zero page variables
print_a equ $ffd2
temp_ptr equ $FB ; scratch space in page zero


;start of code
;BASIC stub
  org $801
  dc.b $0b,$08,$d4,$07,$9e,$32,$30,$36,$31,$00,$00,$00
  
  
  ldaxi #NB65_CART_SIGNATURE  ;where signature should be in cartridge (if cart is banked in)
  jsr  look_for_signature
  bcc found_nb65_signature

  ldaxi #NB65_RAM_STUB_SIGNATURE  ;where signature should be in a RAM stub
  jsr  look_for_signature
  bcs nb65_signature_not_found
  jsr NB65_RAM_STUB_ACTIVATE     ;we need to turn on NB65 cartridge
  jmp found_nb65_signature
  
nb65_signature_not_found
  ldaxi #nb65_api_not_found_message
  jsr print_ax
  rts

found_nb65_signature

  print #initializing
  nb65call #NB65_INITIALIZE
	bcc .init_ok
  print_cr
  print #failed
  print_cr
  jsr print_errorcode
  jmp reset_after_keypress    
.init_ok

;if we got here, we have found the NB65 API and initialised the IP stack
;print out the current configuration
  nb65call #NB65_PRINT_IP_CONFIG
  
  
;now set up for the nb65callback test
  
  ldaxi  #64     ;listen on port 64
  stax nb65_param_buffer+NB65_UDP_LISTENER_PORT
  ldaxi  #udp_nb65callback
  stax nb65_param_buffer+NB65_UDP_LISTENER_CALLBACK
  ldaxi  #nb65_param_buffer
  nb65call   #NB65_UDP_ADD_LISTENER
  bcc .add_listener_ok 
  print #failed
  jsr print_errorcode
  jmp reset_after_keypress
.add_listener_ok

  print #listening	
  

.loop_forever
  jsr NB65_PERIODIC_PROCESSING_VECTOR
  jmp .loop_forever


;here is the code that will execute whenever a UDP packet arrives on port 64
udp_nb65callback subroutine
  
  
  ldaxi #nb65_param_buffer
  nb65call #NB65_GET_INPUT_PACKET_INFO
  
  print_cr
  print #recv_from
  ldaxi #nb65_param_buffer+NB65_REMOTE_IP
  nb65call #NB65_PRINT_DOTTED_QUAD
  print #port
  lda nb65_param_buffer+NB65_REMOTE_PORT+1
  nb65call #NB65_PRINT_HEX  
  lda nb65_param_buffer+NB65_REMOTE_PORT
  nb65call #NB65_PRINT_HEX
  print_cr
  print #length
  lda nb65_param_buffer+NB65_PAYLOAD_LENGTH+1
  nb65call #NB65_PRINT_HEX
  lda nb65_param_buffer+NB65_PAYLOAD_LENGTH
  nb65call #NB65_PRINT_HEX
  print_cr  
  print #data
  ldax nb65_param_buffer+NB65_PAYLOAD_POINTER
  stax temp_ptr
  ldx nb65_param_buffer+NB65_PAYLOAD_LENGTH ;assumes length is < 255
  ldy #0
.next_byte
  lda (temp_ptr),y
  jsr print_a
  iny
  dex
  bpl .next_byte


  print_cr

  ;make and send a reply
  ldaxi #reply_message
  stax nb65_param_buffer+NB65_PAYLOAD_POINTER

  ldaxi #reply_message_length
  stax nb65_param_buffer+NB65_PAYLOAD_LENGTH

  ldaxi #nb65_param_buffer
  nb65call #NB65_SEND_UDP_PACKET  
  bcc .sent_ok
  jmp print_errorcode
.sent_ok
  print #reply_sent

  rts


;look for NB65 signature at location pointed at by AX
look_for_signature subroutine
  stax temp_ptr
  ldy #3
.check_one_byte
  lda (temp_ptr),y
  cmp nb65_signature,y
  bne .bad_match  
  dey 
  bpl .check_one_byte  
  clc
  rts
.bad_match
  sec
  rts

print_ax subroutine
  stax temp_ptr
  ldy #0
.next_char 
  lda (temp_ptr),y
  beq .done
  jsr print_a
  iny
  jmp .next_char
.done
  rts
  
get_key
  jsr $ffe4
  cmp #0
  beq get_key
  rts

reset_after_keypress
  print  #press_a_key_to_continue    
  jsr get_key
  jmp $fce2   ;do a cold start


print_errorcode
  print #error_code
  nb65call #NB65_GET_LAST_ERROR
  nb65call #NB65_PRINT_HEX
  print_cr
  rts

  

;constants
nb65_api_not_found_message dc.b "ERROR - NB65 API NOT FOUND.",13,0
nb65_signature dc.b $4E,$42,$36,$35  ; "NB65"  - API signature
initializing dc.b "INITIALIZING ",13,0
error_code dc.b "ERROR CODE: $",0
press_a_key_to_continue dc.b "PRESS A KEY TO CONTINUE",13,0
failed dc.b "FAILED ", 0
ok dc.b "OK ", 0
recv_from dc.b"RECEIVED FROM: ",0
listening dc.b "LISTENING ON UDP PORT 64",13,0
reply_sent dc.b "REPLY SENT.",0
port dc.b " PORT: $",0
length dc.b "LENGTH: $",0
data dc.b "DATA: ",0
space_colon_space dc.b " : ",0
reply_message dc.b "PONG!"
reply_message_length equ 5

;variables
nb65_param_buffer DS.B $20  




;-- LICENSE FOR dasm_example.asm --
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
