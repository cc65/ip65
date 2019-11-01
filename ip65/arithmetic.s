; helper routines for arithmetic on 32 bit numbers

.include "zeropage.inc"
.include "../inc/common.inc"


.bss

temp_ax: .res 2


.code

; no 16bit operand as can just use AX
.exportzp acc32 = ptr1          ; 32bit accumulater (pointer)
.exportzp op32  = ptr2          ; 32 bit operand (pointer)
.exportzp acc16 = acc32         ; 16bit accumulater (value, NOT pointer)

.export add_32_32
.export add_16_32

.export sub_16_16

.export cmp_32_32
.export cmp_16_16

;dengland
.export	gte_32_32
;---

.export mul_8_16

; compare 2 32bit numbers
; on exit, zero flag clear iff acc32==op32
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
 
;dengland 
; 	Compare two 32 bit numbers.  
;	Set carry if acc32 >= op32 else clear carry
gte_32_32:
		LDY	#$03
		LDA 	(acc32), Y  ; compare high bytes
		CMP 	(op32), Y
		BCC 	@LABEL1 ; if NUM1H < NUM2H then NUM1 < NUM2
		BNE 	@LABEL2 ; if NUM1H <> NUM2H then NUM1 > NUM2 (so NUM1 >= NUM2)
		DEY
		LDA 	(acc32), Y  ; compare high bytes
		CMP 	(op32), Y
		BCC 	@LABEL1 ; if NUM1H < NUM2H then NUM1 < NUM2
		BNE 	@LABEL2 ; if NUM1H <> NUM2H then NUM1 > NUM2 (so NUM1 >= NUM2)
		DEY
		LDA 	(acc32), Y  ; compare middle bytes
		CMP 	(op32), Y
		BCC 	@LABEL1 ; if NUM1M < NUM2M then NUM1 < NUM2
		BNE 	@LABEL2 ; if NUM1M <> NUM2M then NUM1 > NUM2 (so NUM1 >= NUM2)
		DEY
		LDA 	(acc32), Y  ; compare low bytes
		CMP 	(op32), Y
		BCS 	@LABEL2 ; if NUM1L >= NUM2L then NUM1 >= NUM2
@LABEL1:
		CLC
		RTS
@LABEL2:
		SEC
		RTS
;---


; compare 2 16bit numbers
; on exit, zero flag clear iff acc16==AX
cmp_16_16:
  cmp acc16
  bne @exit
  txa
  cmp acc16+1
@exit:
  rts

; subtract 2 16 bit numbers
; acc16=acc16-AX
sub_16_16:
  stax temp_ax
  sec
  lda acc16
  sbc temp_ax
  sta acc16
  lda acc16+1
  sbc temp_ax+1
  sta acc16+1
  rts

; add a 32bit operand to the 32 bit accumulater
; acc32=acc32+op32
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

; add a 16bit operand to the 32 bit accumulater
; acc32=acc32+AX
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

; multiply a 16 bit number by an 8 bit number
; acc16=acc16*a
mul_8_16:
  tax
  beq @operand_is_zero
  lda acc16
  sta temp_ax
  lda acc16+1
  sta temp_ax+1

@addition_loop:
  dex
  beq @done
  clc
  lda acc16
  adc temp_ax
  sta acc16
  lda acc16+1
  adc temp_ax+1
  sta acc16+1
  jmp @addition_loop

@done:
  rts
@operand_is_zero:
  sta acc16
  sta acc16+1
  rts



; -- LICENSE FOR arithmetic.s --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
;
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
;
; The Original Code is ip65.
;
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.
; -- LICENSE END --
