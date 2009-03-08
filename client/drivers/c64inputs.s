.export get_key  

.code
get_key:
  jsr $ffe4
  cmp #0
  beq get_key
  rts
  