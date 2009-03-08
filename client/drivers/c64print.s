
.export print_a
.export print_cr
.export cls
.export beep

.data
print_a = $ffd2

.code

print_cr:
  lda #13
  jmp print_a

cls:
    lda #147  ; 'CLR/HOME'
    jmp print_a

beep:
  rts