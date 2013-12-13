
.export print_a
.export print_cr
.export cls
.export beep
.export print_a_inverse

.exportzp screen_current_row
.exportzp screen_current_col


screen_current_row=$d6
screen_current_col=$d3


;use C64 Kernel ROM function to print a character to the screen
;inputs: A contains petscii value of character to print
;outputs: none
print_a = $ffd2

.bss
beep_timer: .res 1

.code

;use C64 Kernel ROM function to move to a new line
;inputs: none
;outputs: none
print_cr:
  lda #13
  jmp print_a

;use C64 Kernel ROM function to clear the screen
;inputs: none
;outputs: none
cls:
    lda #147  ; 'CLR/HOME'
    jmp print_a

;currently does nothing (should make a 'beep noise')
;inputs: none
;outputs: none
beep:
  lda #15
  sta $d418	;set volume

  lda #0
  sta $d405
  lda #240
  sta $d406
  lda #8
  sta $d403

  ;tone values for voice 1
  lda #48
  sta $d400
  lda #28
  sta $d401

  ;enable tone register
  lda #65
  sta $d404


; pause for qtr second
  lda $dd06   ;
  sta beep_timer
  inc beep_timer  ;time counts backwards
:  
  lda $dd06   ;
  cmp beep_timer
  bne :-

  ;disable tone register
  lda #65
  sta $d404
  lda #0
  sta $d418	;set volume

  rts

  
;print a single char in inverse text:
print_a_inverse:
  pha
  lda #18 ;inverse mode on 
  jsr print_a
  pla
  jsr print_a
  lda #146 ;inverse mode off
  jmp print_a



;-- LICENSE FOR c64print.s --
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
