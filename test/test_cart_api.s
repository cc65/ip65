;test the "Kipper Kartridge API"
.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.include "../ip65/copymem.s"

; load A/X macro
	.macro ldax arg
	.if (.match (.left (1, arg), #))	; immediate mode
	lda #<(.right (.tcount (arg)-1, arg))
	ldx #>(.right (.tcount (arg)-1, arg))
	.else					; assume absolute or zero page
	lda arg
	ldx 1+(arg)
	.endif
	.endmacro

; store A/X macro
.macro stax arg
	sta arg
	stx 1+(arg)
.endmacro	

print_a = $ffd2

.macro cout arg
  lda arg
  jsr print_a
.endmacro   
    
  .zeropage
  temp_ptr:		.res 2
  
  .bss
  kipper_param_buffer: .res $20  
  block_number: .res $0
  
.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

.word basicstub		; load address

.macro print arg
  ldax arg
	ldy #KPR_PRINT_ASCIIZ
  jsr KPR_DISPATCH_VECTOR 
.endmacro 

.macro print_cr
  lda #13
	jsr print_a
.endmacro

.macro call arg
	ldy arg
  jsr KPR_DISPATCH_VECTOR   
.endmacro

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


;look for KIPPER signature at location pointed at by AX
look_for_signature: 
  stax temp_ptr
  ldy #5
@check_one_byte:
  lda (temp_ptr),y
  cmp kipper_signature,y
  bne @bad_match  
  dey 
  bpl@check_one_byte  
  clc
  rts
@bad_match:
  sec
  rts
  
init:
  

  ldax #KPR_CART_SIGNATURE  ;where signature should be in cartridge
  jsr  look_for_signature
  bcc @found_kipper_signature
  jmp kipper_signature_not_found
  
@found_kipper_signature:

  print #initializing

  ldy #KPR_INITIALIZE
  jsr KPR_DISPATCH_VECTOR 
	bcc :+  
  print #failed
  jsr print_errorcode
  jmp bad_boot    
:  

  print #ok
  print_cr
  
  call #KPR_PRINT_IP_CONFIG
  
;DNS resolution test 
  
  ldax #test_hostname
  stax kipper_param_buffer+KPR_DNS_HOSTNAME

  call #KPR_PRINT_ASCIIZ  

  cout #' '
  cout #':'
  cout #' '
  
  ldax  #kipper_param_buffer
  call #KPR_DNS_RESOLVE
  bcc :+
  print #dns_lookup_failed_msg
  print_cr
  jmp print_errorcode
:  
  ldax #kipper_param_buffer+KPR_DNS_HOSTNAME_IP
  call #KPR_PRINT_DOTTED_QUAD
  print_cr
 
 ldax #64
 call #KPR_UDP_REMOVE_LISTENER  ;should generate an error since there is no listener on  port 64
  jsr print_errorcode

  
;tftp send test
  lda #0
  sta block_number
  ldax #test_file
  stax kipper_param_buffer+KPR_TFTP_FILENAME
  ldax #tftp_upload_callback
  stax kipper_param_buffer+KPR_TFTP_POINTER
  ldax #kipper_param_buffer
  call #KPR_TFTP_CALLBACK_UPLOAD
  bcc :+
  jmp print_errorcode
:


@download_test:
;tftp download callback test
  lda #0
  sta block_number
  ldax #test_file
  stax kipper_param_buffer+KPR_TFTP_FILENAME
  ldax #tftp_download_callback
  stax kipper_param_buffer+KPR_TFTP_POINTER
  ldax #kipper_param_buffer
  call #KPR_TFTP_CALLBACK_DOWNLOAD
    bcc :+
  jmp print_errorcode
:
  lda #'$'
  jsr print_a
  lda  kipper_param_buffer+KPR_TFTP_FILESIZE+1
  jsr print_hex
  lda  kipper_param_buffer+KPR_TFTP_FILESIZE
  jsr print_hex
  print #bytes_download
  print_cr
  
;udp callback test
  
  ldax  #64     ;listen on port 64
  stax kipper_param_buffer+KPR_UDP_LISTENER_PORT
  ldax  #udp_callback
  stax kipper_param_buffer+KPR_UDP_LISTENER_CALLBACK
  ldax  #kipper_param_buffer
  call   #KPR_UDP_ADD_LISTENER
	bcc :+  
  print #failed
  jsr print_errorcode
  jmp bad_boot    
:

  print #listening	
  

@loop_forever:
  jsr KPR_PERIODIC_PROCESSING_VECTOR
  jmp @loop_forever
  
  
tftp_upload_callback:
  stax copy_dest
  inc block_number
  print #sending
  print #block_no
  lda block_number
  jsr print_hex
  print_cr
  
  lda block_number
  asl
  cmp #$10
  beq @last_block
  clc
  adc #$a0
  tax
  lda #0
  stax copy_src
  ldax #$200
  jsr copymem
  ldax #$200
  rts
@last_block:  
  ldax #0
  rts

tftp_download_callback:
  inc block_number
  print #received
  print #block_no
  lda block_number
  jsr print_hex
  print_cr
  rts

udp_callback:

  ldax #kipper_param_buffer
  call #KPR_GET_INPUT_PACKET_INFO

  print #port

  lda kipper_param_buffer+KPR_LOCAL_PORT+1
  call #KPR_PRINT_HEX

  lda kipper_param_buffer+KPR_LOCAL_PORT
  call #KPR_PRINT_HEX

  print_cr

  print #received
  print #from

  ldax #kipper_param_buffer+KPR_REMOTE_IP
  call #KPR_PRINT_DOTTED_QUAD
  
  cout #' '
  
  print #port
  
  lda kipper_param_buffer+KPR_REMOTE_PORT+1
  call #KPR_PRINT_HEX  
  lda kipper_param_buffer+KPR_REMOTE_PORT
  call #KPR_PRINT_HEX
  
  print_cr
  
  print #length

  lda kipper_param_buffer+KPR_PAYLOAD_LENGTH+1
  call #KPR_PRINT_HEX
  lda kipper_param_buffer+KPR_PAYLOAD_LENGTH
  call #KPR_PRINT_HEX
  print_cr  
  print #data

  ldax kipper_param_buffer+KPR_PAYLOAD_POINTER
  
  stax temp_ptr
  ldx kipper_param_buffer+KPR_PAYLOAD_LENGTH ;assumes length is < 255
  ldy #0
:
  lda (temp_ptr),y
  jsr print_a
  iny
  dex
  bpl :-
  
  print_cr

;make and send reply
  ldax #reply_message
  stax kipper_param_buffer+KPR_PAYLOAD_POINTER

  ldax #reply_message_length
  stax kipper_param_buffer+KPR_PAYLOAD_LENGTH
 
  ldax #kipper_param_buffer
  call #KPR_SEND_UDP_PACKET  
  bcc :+
  jmp print_errorcode
:
  print #reply_sent
  rts
  
bad_boot:
  print  #press_a_key_to_continue
restart:    
  jsr get_key
  jmp $fce2   ;do a cold start


print_errorcode:
  print #error_code
  call #KPR_GET_LAST_ERROR
  call #KPR_PRINT_HEX
  print_cr
  rts

kipper_signature_not_found:

  ldy #0
:
  lda kipper_signature_not_found_message,y
  beq restart
  jsr print_a
  iny
  jmp :-
  

;use C64 Kernel ROM function to read a key
;inputs: none
;outputs: A contains ASCII value of key just pressed
get_key:
  jsr $ffe4
  cmp #0
  beq get_key
  rts
  
  print_hex:
  pha  
  pha  
  lsr
  lsr
  lsr
  lsr
  tax
  lda hexdigits,x
  jsr print_a
  pla
  and #$0F
  tax
  lda hexdigits,x
  jsr print_a
  pla
  rts

.rodata
hexdigits:
.byte "0123456789ABCDEF"

test_hostname:
  .byte "RETROHACKERS.COM",0          ;this should be an A record

  received:  
  .asciiz "RECEIVED "
  sending: 
  .asciiz "SENDING "
  from:  
  .asciiz " FROM: "
  
listening:  
  .byte "LISTENING ON UDP PORT 64",13,0


reply_sent:  
  .byte "REPLY SENT.",13,0


initializing:  
  .byte "INITIALIZING ",0

port:  
  .byte "PORT: $",0

length:  
  .byte "LENGTH: $",0
  
data:
  .byte "DATA: ",0

block_no:  
  .byte "BLOCK: $",0

error_code:  
  .asciiz "ERROR CODE: $"
press_a_key_to_continue:
  .byte "PRESS A KEY TO CONTINUE",13,0

failed:
	.byte "FAILED ", 0

ok:
	.byte "OK ", 0
 
 kipper_signature_not_found_message:
 .byte "NO KIPPER API FOUND",13,"PRESS ANY KEY TO RESET", 0
 
dns_lookup_failed_msg:
 .byte "DNS LOOKUP FAILED", 0

bytes_download: .byte "BYTES DOWNLOADED",13,0

reply_message:
  .byte "PONG!"
reply_message_end:
reply_message_length=reply_message_end-reply_message

test_file:
.byte "TESTFILE.BIN",0

kipper_signature:
  .byte "KIPPER" ; API signature


;-- LICENSE FOR test_cart_api.s --
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
