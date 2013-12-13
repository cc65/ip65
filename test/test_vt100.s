
.ifndef KIPPER_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.include "../inc/common.i"
.include "../inc/commonprint.i"
.import print_a
.import cfg_get_configuration_ptr

.import get_key
.import timer_init
.import beep
.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

.word basicstub		; load address

.import vt100_init_terminal
.import vt100_process_inbound_char

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

.code
init:

  jsr timer_init
  jsr vt100_init_terminal
  ldax #string1
  jsr emit_string
  
  rts


emit_string:
  stax  next_byte+1
:  
  jsr next_byte
  
  beq @done
  jsr vt100_process_inbound_char
  jmp :-
@done:
  rts
  
next_byte:
  lda $ffff
  inc next_byte+1
  bne :+
  inc next_byte+2
:
  cmp #0
  rts
  

.rodata

string1:
.byte $1b,"[H"  ;HOME
.byte "hello world",13,10
.byte $1b,"[1m"  ;BOLD
.byte "hello bold",13,10
.byte $1b,"[7m"  ;reverse
.byte "hello reverse bold",13,10
.byte $1b,"7" ;save cursor position & attributes
.byte $1b,"[m"  ;normal
.byte "hello normal",13,10
.byte 07
.byte "that was a beep!",13,10
.byte $1b,"8" ;restor cursor position & attributes
.byte $1b,"[20;1H"; ;move to row 20, pos 1
.byte "ABCDEFGhijklmnopqRsTuVwXyZ01234567890"
.byte $1b,"[20;10f"; ;move to row 20, pos 1
.byte $1b,"[1K"

.byte 0

;-- LICENSE FOR test_vt00.s --
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
