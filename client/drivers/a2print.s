
.export print_a
.export print_cr
.export cls

.code

print_a:
  ora  #$80  ;turn ASCII into Apple 2 screen codes
  jmp $fdf0


print_cr:

  jmp $fd8e
    

  
cls:
    jmp $fc58
  rts
