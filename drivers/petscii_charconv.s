;ASCII/PETSCII conversion tables
;cribbed from http://www.ffd2.com/fridge/misc/petcom.c


.export ascii_to_native
.export native_to_ascii

;given a PETSCII char in A, return equivalent ASCII
native_to_ascii:
  tax
  lda petscii_to_ascii_table,x
  rts

;given an ASCII char in A, return equivalent PETSCII
ascii_to_native:
  tax
  lda ascii_to_petscii_table,x
  rts

.rodata
ascii_to_petscii_table:
.byte $00,$01,$02,$03,$04,$05,$06,$07,$14,$20,$0d,$11,$93,$0a,$0e,$0f
.byte $10,$0b,$12,$13,$08,$15,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f
.byte $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f
.byte $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f
.byte $40,$c1,$c2,$c3,$c4,$c5,$c6,$c7,$c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf
.byte $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$da,$5b,$5c,$5d,$5e,$a4
.byte $c0,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f
.byte $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$db,$dc,$dd,$de,$df
.byte $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8a,$8b,$8c,$8d,$8e,$8f
.byte $90,$91,$92,$0c,$94,$95,$96,$97,$98,$99,$9a,$9b,$9c,$9d,$9e,$9f
.byte $a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab,$ac,$ad,$ae,$af
.byte $b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9,$ba,$bb,$bc,$bd,$be,$bf
.byte $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f
.byte $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$7b,$7c,$7d,$7e,$7f
.byte $e0,$e1,$e2,$e3,$e4,$e5,$e6,$e7,$e8,$e9,$ea,$eb,$ec,$ed,$ee,$ef
.byte $f0,$f1,$f2,$f3,$f4,$f5,$f6,$f7,$f8,$f9,$fa,$fb,$fc,$fd,$fe,$ff

petscii_to_ascii_table:
.byte $00,$01,$02,$03,$04,$05,$06,$07,$14,$09,$0d,$11,$93,$0a,$0e,$0f
.byte $10,$0b,$12,$13,$08,$15,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f
.byte $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f
.byte $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f
.byte $40,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f
.byte $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$5b,$5c,$5d,$5e,$5f
.byte $c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7,$c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf
.byte $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$da,$db,$dc,$dd,$de,$df
.byte $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8a,$8b,$8c,$8d,$8e,$8f
.byte $90,$91,$92,$0c,$94,$95,$96,$97,$98,$99,$9a,$9b,$9c,$9d,$9e,$9f
.byte $20,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab,$ac,$ad,$ae,$af
.byte $b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9,$ba,$bb,$bc,$bd,$be,$bf
.byte $60,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f
.byte $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$7b,$7c,$7d,$7e,$7f
.byte $a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab,$ac,$ad,$ae,$af
.byte $b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9,$ba,$bb,$bc,$bd,$be,$bf



;-- LICENSE FOR c64charconv.s --
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
