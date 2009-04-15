.export get_key  
.export check_for_abort_key
.code
;use Apple 2 monitor ROM function to read from keyboard
;inputs: none
;outputs: A contains ASCII code of key pressed
get_key:
  jmp $fd1b
  
  
;check whether the escape key is being pressed
;inputs: none
;outputs: sec if escape pressed, clear otherwise
check_for_abort_key:
lda $c000 ;current key pressed
cmp #$9B
bne :+
sec
rts
:
clc
rts
