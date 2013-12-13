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

  lda #14
  jsr print_a ;switch to lower case

  print #initializing

  lda #$4c
  sta $4000
  ldax #print_vars
  stax $4001
  
  
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
  print #listening
  ldax #httpd_callback
;  ldax #$0000
  call #KPR_HTTPD_START
  jsr print_errorcode
  rts
 
 
print_vars:
  
  lda #'h'
  call #KPR_HTTPD_GET_VAR_VALUE
  bcs :+
  call #KPR_PRINT_ASCIIZ
  print #said
  lda #'m'
  call #KPR_HTTPD_GET_VAR_VALUE
  bcs :+
  call #KPR_PRINT_ASCIIZ
  print_cr
:  
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

;use C64 Kernel ROM function to read a key
;inputs: none
;outputs: A contains ASCII value of key just pressed
get_key:
  jsr $ffe4
  cmp #0
  beq get_key
  rts
  
kipper_signature_not_found:

  ldy #0
:
  lda kipper_signature_not_found_message,y
  beq restart
  jsr print_a
  iny
  jmp :-

httpd_callback:
  jsr print_vars
  ldax #html
  ldy #2 ;text/html
  clc
  rts
  

.rodata

kipper_signature:
  .byte "KIPPER" ; API signature
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
initializing:  
  .byte "INITIALIZING ",0
listening:
  .byte "LISTENING",0
said:
  .byte ":",0
html:
  .byte "<h1>hello world</h1>%?mMessage recorded as '%$h:%$m'%.<form>Your Handle:<input name=h type=text length=20 value='%$h'><br>Your Message: <input type=text lengh=60 name='m'><br><input type=submit></form><br>",0

;-- LICENSE FOR test_httpd.s --
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
