
.export print_a
.export print_cr
.export cls
.export beep
.export print_a_inverse
.import timer_read
.exportzp screen_current_row
.exportzp screen_current_col

screen_current_row=$d6
screen_current_col=$d3

;use VIC 20 Kernel ROM function to print a character to the screen
;inputs: A contains petscii value of character to print
;outputs: none
print_a = $ffd2

.bss
beep_timer: .res 1

.code

;use VIC 20 Kernel ROM function to move to a new line
;inputs: none
;outputs: none
print_cr:
  lda #13
  jmp print_a

;use VIC 20 Kernel ROM function to clear the screen
;inputs: none
;outputs: none
cls:
    lda #147  ; 'CLR/HOME'
    jmp print_a

;currently does nothing (should make a 'beep noise')
;inputs: none
;outputs: none
beep:
  lda $900e
  ora #15
  sta $900e	;set volume

  ;turn on osc. 3
  lda #$FF
  sta $900c

; pause for qtr second
  jsr timer_read
  stx beep_timer
  inc beep_timer
  inc beep_timer  
:  
  jsr timer_read
  cpx beep_timer
  bne :-

  ;turn off osc. 3
  lda #$00
  sta $900c

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
