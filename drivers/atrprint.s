.include "../inc/common.i"

.export print_a
.export print_a_inverse
.export print_cr
.export cls
.export beep
.exportzp screen_current_row
.exportzp screen_current_col

screen_current_col = $55        ; 2-byte cursor column
screen_current_row = $54        ; 1-byte cursor row


.bss

char: .res 1


.code

; use ATARI CIOV function to display 1 char
; inputs: A should be set to ASCII char to display
; outputs: none
print_a:
  cmp #10                       ; is it a CR?
  bne @not_lf
  lda #155                      ; CR/LF char
@not_lf:
  cmp #13                       ; is it a LF?
  bne @not_cr
  lda #155                      ; CR/LF char
@not_cr:
  sta char
  txa
  pha
  tya
  pha
  ldax #1
  stax $0348                    ; 2-byte buffer length
  ldax #char
  stax $0344                    ; 2-byte buffer address
  ldx #11                       ; put character(s)
  stx $0342                     ; COMMAND CODE
  ldx #0
  jsr $e456                     ; vector to CIO
  pla
  tay
  pla
  tax
  rts

; use ATARI CIOV function to move to new line
; inputs: none
; outputs: none
print_cr:
  lda #155                      ; CR/LF char
  jmp print_a

; use ATARI CIOV function to clear the screen
; inputs: none
; outputs: none  
cls:
  lda #125                      ; clear screen
  jmp print_a

; use ATARI CIOV function to make a 'beep' noise
; inputs: none
; outputs: none
beep:
  lda #253                      ; beep char
  jmp print_a

print_a_inverse:
  ora  #$80                     ; turn on top bit
  jmp print_a



;-- LICENSE FOR atrprint.s --
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
