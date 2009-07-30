
.export print_a
.export print_cr
.export cls
.export beep
.code

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