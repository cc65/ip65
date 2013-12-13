  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  
  .import exit_to_basic  
  
  .import parse_dotted_quad
  .import dotted_quad_value
  
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__
  .import  __DATA_SIZE__
  

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

.segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-$11                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; Size
        jmp init

.code

init:
    
  jsr print_cr
  
  ldax #dotted_quad_1
  jsr test_dotted_quad_string  

  ldax #dotted_quad_2
  jsr test_dotted_quad_string  

  ldax #dotted_quad_3
  jsr test_dotted_quad_string  

  ldax #dotted_quad_4
  jsr test_dotted_quad_string  

  ldax #dotted_quad_5
  jsr test_dotted_quad_string  

  ldax #dotted_quad_6
  jsr test_dotted_quad_string  

  ldax #dotted_quad_7
  jsr test_dotted_quad_string  

  jmp exit_to_basic

test_dotted_quad_string:
  stax  temp_ax
  jsr print
  lda #':'
  jsr print_a
  lda #' '
  jsr print_a
  ldax  temp_ax
  jsr parse_dotted_quad   
  bcs @error
  ldax #dotted_quad_value
  jsr print_dotted_quad
  jsr print_cr
  rts

@error:
  ldax  #failed_msg
  jsr print
  jsr print_cr
  rts
  
  .bss
  temp_ax: .res 2
  
	.rodata


dotted_quad_1:
  .byte "1.1.1.1",0 ;should work

dotted_quad_2:
  .byte "GOOBER",0  ;should fail

dotted_quad_3:
  .byte "255.255.255.0",0     ;should work

dotted_quad_4:
  .byte "111.222.333.444",0   ;should fail 

dotted_quad_5:   
  .byte "111.22.3",0  ; should fail

dotted_quad_6:   
  .byte "111.22.3.4",0 ; should work
  
dotted_quad_7:   
  .byte "3.4.5.6X",0 ; should fail




;-- LICENSE FOR testdottedquad.s --
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
