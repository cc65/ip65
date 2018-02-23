.include "../inc/common.inc"
.include "../inc/commonprint.inc"

.export start
.export telnet_close       = $1000
.export telnet_send_char   = $1000
.export telnet_send_string = $1000

.import exit_to_basic
.import timer_init
.import vt100_init_terminal
.import vt100_process_inbound_char


; keep LD65 happy
.segment "INIT"
.segment "ONCE"


.segment "STARTUP"

start:
  jsr timer_init
  jsr vt100_init_terminal
  ldax #string1
  jsr emit_string
  jmp exit_to_basic

emit_string:
  stax next_byte+1
: jsr next_byte
  beq @done
  jsr vt100_process_inbound_char
  jmp :-
@done:
  rts

next_byte:
  ldy $ffff
  inc next_byte+1
  bne :+
  inc next_byte+2
: cpy #0
  rts


.rodata

string1:
.byte $1b,"[H"                  ; HOME
.byte "hello world",13,10
.byte $1b,"[1m"                 ; BOLD
.byte "hello bold",13,10
.byte $1b,"[7m"                 ; reverse
.byte "hello reverse bold",13,10
.byte $1b,"7"                   ; save cursor position & attributes
.byte $1b,"[m"                  ; normal
.byte "hello normal",13,10
.byte 07
.byte "that was a beep!",13,10
.byte $1b,"8"                   ; restore cursor position & attributes
.byte $1b,"[20;1H";             ; move to row 20, pos 1 (using CUP)
.byte "ABCDEFGhijklmnopqRsTuVwXyZ01234567890"    ; these characters are drawn in inverse (old attribute)
.byte $1b,"[20;10f";            ; move to row 20, pos 10 (using HVP)
.byte $1b,"[1K"                 ; erase from start of line to cursor position (EL)
.byte 13,10
.byte $1b,"[0m"                 ; attributes off (SGR)
.byte $1b,")0"                  ; select special graphics G1 (SCS)
.byte $0e                       ; SO
.byte "lqqkx`abcdefghijmnopqrstuvwyz{|}~"        ; line drawing chars
.byte $0f                       ; SI
.byte 13,10

.byte 0



;-- LICENSE FOR vt00.s --
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
