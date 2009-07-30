;ASCII/PETSCII conversion tables
;cribbed from http://www.ffd2.com/fridge/misc/petcom.c


.export ascii_to_native
.export native_to_ascii

;given an A2 Screen Code char in A, return equivalent ASCII
native_to_ascii:
;just strip high bit
  and #$7f
  rts

;given an ASCII char in A, return equivalent A2 Screen Code
ascii_to_native:
;set high bit
  ora #$80
  rts

