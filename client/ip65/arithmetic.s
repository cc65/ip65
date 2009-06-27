.include "../inc/common.i"

;helper routines for arithmetic on 32 bit numbers 

;reuse the copy_* zero page locations as pointers for 32bit addition
.importzp copy_src
.importzp copy_dest

acc32 =copy_src       ;32bit accumulater (pointer)
op32 =copy_dest       ;32 bit operand (pointer)

acc16 =acc32       ;16bit accumulater (value, NOT pointer)


;no 16bit operand as can just use AX    
.exportzp acc32
.exportzp op32
.exportzp acc16

.export add_32_32
.export add_16_32

.export cmp_32_32
.export cmp_16_16

;compare 2 32bit numbers
;on exit, zero flag clear iff acc32==op32
cmp_32_32:
  ldy #0
  lda (op32),y
  cmp (acc32),y
  bne @exit
  iny  
  lda (op32),y
  cmp (acc32),y
  bne @exit
  iny
  lda (op32),y
  cmp (acc32),y
  bne @exit
  iny
  lda (op32),y
  cmp (acc32),y
@exit:  
  rts

;compare 2 16bit numbers
;on exit, zero flag clear iff acc16==AX
cmp_16_16:
  cmp acc16
  bne @exit
  txa
  cmp acc16+1
@exit:  
  rts
  
;add a 32bit operand to the 32 bit accumulater
;acc32=acc32+op32
add_32_32:
  clc
  ldy #0
  lda (op32),y
  adc (acc32),y
  sta (acc32),y  
  iny
  lda (op32),y
  adc (acc32),y
  sta (acc32),y  
  iny
  lda (op32),y
  adc (acc32),y
  sta (acc32),y  
  iny
  lda (op32),y
  adc (acc32),y
  sta (acc32),y  
    
  rts
  

;add a 16bit operand to the 32 bit accumulater
;acc32=acc32+AX
add_16_32:
  clc
  ldy #0
  adc (acc32),y
  sta (acc32),y  
  iny
  txa
  adc (acc32),y
  sta (acc32),y  
  iny
  lda #0
  adc (acc32),y
  sta (acc32),y
  iny
  lda #0
  adc (acc32),y
  sta (acc32),y
  rts
  
