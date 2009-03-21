
.export print_a
.export print_cr
.export cls
.export beep

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