
.ifndef KIPPER_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.include "../inc/common.i"
.include "../inc/commonprint.i"
.import print_a
.import cfg_get_configuration_ptr
.import  io_device_no
.import  io_sector_no
.import  io_track_no
.import  io_read_sector
.import  io_write_sector

.import io_read_file_with_callback
.import io_read_file
.import io_filename
.import io_filesize
.import io_load_address
.import io_callback
.import get_key
.import ip65_error
.import ip65_process
.import io_read_catalogue_ex

.macro cout arg
  lda arg
  jsr print_a
.endmacro   



.bss
 sector_buffer: .res 256
 output_buffer: .res 520
 .export output_buffer
current_byte_in_row: .res 1
current_byte_in_sector: .res 1
start_of_current_row: .res 1

directory_buffer: .res 4096

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
  lda #14
  jsr print_a ;switch to lower case 
  lda     $dc08 ;read deci-seconds - start clock ticking
  sta  $dc08
  jsr load_buffer
@loop:
  lda #5  ;timeout period
  jsr getc
  bcs @done
  jsr print_a
  jmp @loop
@done:
  rts

load_buffer:
  ldax #buffer
  stax next_char_ptr
  ldax #buffer_length
  stax buff_length
  rts


getc:
  sta getc_timeout_seconds

  clc
  lda $dc09  ;time of day clock: seconds (in BCD)
  sed
  adc getc_timeout_seconds
  cmp #$60
  bcc @timeout_set
  sec
  sbc #$60
@timeout_set:  
  cld
  sta getc_timeout_end  

@poll_loop: 
  jsr ip65_process
  jsr next_char
  bcs @no_char
  rts ;done!
@no_char:
  lda $dc09  ;time of day clock: seconds
  cmp getc_timeout_end  
  bne @poll_loop
  sec
  rts
  
next_char:
  lda buff_length
  bne @not_eof
  lda buff_length+1
  bne @not_eof
  sec
  rts
@not_eof:  
  next_char_ptr=*+1
  lda $ffff
  pha
  inc next_char_ptr
  bne :+
  inc next_char_ptr+1
:  
  sec
  lda   buff_length
  sbc #1
  sta   buff_length
  lda   buff_length+1
  sbc #0
  sta   buff_length+1
  pla
  clc
  
  rts
  
.rodata
buffer:
  .byte "this is a test1!",13
  .byte "this is a test2!",13
  .byte "this is a test3!",13
  .byte "this is a test4!",13
  .byte "this is a test5!",13
  .byte "this is a test6!",13
  .byte "this is a test7!",13
  .byte "this is a test8!",13
  .byte "this is a test9!",13
  .byte "this is a test10!",13
  .byte "this is a test1@",13
  .byte "this is a test2@",13
  .byte "this is a test3@",13
  .byte "this is a test4@",13
  .byte "this is a test5@",13
  .byte "this is a test6@",13
  .byte "this is a test7@",13
  .byte "this is a test8@",13
  .byte "this is a test9@",13
  .byte "this is a test10@",13
  .byte "this is a test1*",13
  .byte "this is a test2*",13
  .byte "this is a test3*",13
  .byte "this is a test4*",13
  .byte "this is a test5*",13
  .byte "this is a test6*",13
  .byte "this is a test7*",13
  .byte "this is a test8*",13
  .byte "this is a test9*",13
  .byte "this is a test10*",13

buffer_length=*-buffer

.bss
getc_timeout_end: .res 1
getc_timeout_seconds: .res 1
buff_length: .res 2


;-- LICENSE FOR test_getc.s --
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
