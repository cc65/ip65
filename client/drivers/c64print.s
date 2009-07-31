
.export print_a
.export print_cr
.export cls
.export beep
.export print_a_inverse

.exportzp screen_current_row
.exportzp screen_current_col


screen_current_row=$d6
screen_current_col=$d3

.data
;use C64 Kernel ROM function to print a character to the screen
;inputs: A contains petscii value of character to print
;outputs: none
print_a = $ffd2

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
