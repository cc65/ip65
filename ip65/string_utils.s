;text file parsing routines

.export parse_integer
.export parse_hex_digits

.importzp copy_dest

.import mul_8_16
.importzp acc16
  

target_string=copy_dest

.include "../inc/common.i"

.bss
temp_value: .res 2


.code
;parses a string, returns integer (up to 16 bits)
;inputs: AX points to a string containing an integer
;outputs: AX contains integer
parse_integer:
      
  stax  target_string
  lda #0
  sta temp_value
  sta temp_value+1
  tay
@parse_int:
  lda (target_string),y
  cmp #$30
  bcc @end_of_int  ;any non-decimal char should be treated as end of integer   
  cmp #$3A
  bcs @end_of_int  ;any non-decimal char should be treated as end of integer 
   
  ldax  temp_value
  stax  acc16
  lda #10
  jsr mul_8_16
  ldax  acc16
  stax  temp_value
  lda (target_string),y
  sec
  sbc #'0'
  clc
  adc temp_value
  sta temp_value
  bcc @no_rollover  
  inc temp_value+1
@no_rollover:
  iny
  bne @parse_int
@end_of_int:
  ldax temp_value
  clc
  rts


parse_hex_digits:
;parses 2 hex digits, returns a byte
;inputs: X contains high nibble char, A contains low nibble char
;outputs: A contains byte
  pha
  txa
  jsr parse_1_digit
  asl
  asl
  asl
  asl
  sta temp_value
  
  pla
  jsr parse_1_digit
  clc
  adc temp_value
  rts
  
parse_1_digit:
  cmp #$3A
  
  bcs @not_digit
  sec
  sbc #$30
  rts
@not_digit:
  ora #$20  ;make lower case
  sec
  sbc #'a'-10
  rts





;-- LICENSE FOR string_utils.s --
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
