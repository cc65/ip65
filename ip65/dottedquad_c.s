.include "../inc/common.inc"

.export _dotted_quad
.export _parse_dotted_quad

.import parse_dotted_quad
.import dotted_quad_value

.importzp sreg, tmp1, tmp2, tmp3


.bss

dotted_quad: .res 4*4           ; "xxx.xxx.xxx.xxx\0"


.code

_dotted_quad:
  stax dotted_quad_value
  ldax sreg
  stax dotted_quad_value+2

  ldx #$00
  ldy #$00
: jsr convert_byte
  inx
  cpx #4
  bcc :-

  dey
  lda #$00
  sta dotted_quad,y             ; replace last dot with '\0'
  ldax #dotted_quad
  rts

convert_byte:
; hex to bcd routine taken from Andrew Jacob's code at http://www.6502.org/source/integers/hex2dec-more.htm
  sed                           ; switch to decimal mode
  lda #$00                      ; ensure the result is clear
  sta tmp1                      ; BCD low
  sta tmp2                      ; BCD high
  lda #8                        ; the number of source bits
  sta tmp3
: asl dotted_quad_value,x       ; shift out one bit
  lda tmp1                      ; and add into result
  adc tmp1
  sta tmp1
  lda tmp2                      ; propagating any carry
  adc tmp2
  sta tmp2
  dec tmp3                      ; and repeat for next bit
  bne :-
  cld                           ; back to binary

  lda tmp2
  beq :+
  ora #'0'
  sta dotted_quad,y             ; write x00 if not 0
  iny
: lda tmp1
  lsr
  lsr
  lsr
  lsr
  beq :+
  ora #'0'
  sta dotted_quad,y             ; write 0x0 if not 0
  iny
: lda tmp1
  and #$0F
  ora #'0'
  sta dotted_quad,y             ; write 00x
  iny

  lda #'.'
  sta dotted_quad,y             ; write dot
  iny
  rts

_parse_dotted_quad:
  jsr parse_dotted_quad
  bcs error
  ldax dotted_quad_value+2
  stax sreg
  ldax dotted_quad_value
  rts

error:
  ldx #$00
  txa
  stax sreg
  rts
