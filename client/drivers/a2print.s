
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
  and  #$7F  ;turn off bit 8 
  jmp $fded