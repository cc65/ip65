.export get_key  

.code
;use Apple 2 monitor ROM function to read from keyboard
;inputs: none
;outputs: A contains ASCII code of key pressed
get_key:
  jmp $fd1b