
.export print_a
.export print_a_inverse
.export print_cr
.export cls
.export beep
.exportzp screen_current_row
.exportzp screen_current_col

.code

screen_current_col=$24 ; CH - Horizontal cursor-position (0-39)
screen_current_row=$25 ; CV - Vertical cursor-position (0-23)

;
;use Apple 2 monitor ROM function to display 1 char
;inputs: A should be set to ASCII char to display
;outputs: none
print_a:
  ora  #$80  ;turn ASCII into Apple 2 screen codes  
  cmp #$8A   ;is it a line feed?
  bne @not_line_feed
;  jmp print_cr
  pha
  lda #$0
  sta screen_current_col
  pla
@not_line_feed:
  
  jmp $fded


;use Apple 2 monitor ROM function to move to new line
;inputs: none
;outputs: none
print_cr:

  jmp $fd8e
    

;use Apple 2 monitor ROM function to move to clear the screen
;inputs: none
;outputs: none  
cls:
    jmp $fc58

;use Apple 2 monitor ROM function to move to make a 'beep' noise
;inputs: none
;outputs: none
beep:
  jmp $fbdd
  
print_a_inverse:
  and  #$7F  ;turn off top bits
  jsr $fded



;-- LICENSE FOR a2print.s --
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
