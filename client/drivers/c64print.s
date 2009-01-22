
.export print_a
.export print_cr

.data
print_a = $ffd2

.code

print_cr:
  lda #13
  jmp $ffd2

