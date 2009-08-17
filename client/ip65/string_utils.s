;text file parsing routines

.export parse_integer
.importzp copy_dest

.import mul_8_16
.importzp acc16
  

target_string=copy_dest

.include "../inc/common.i"

.bss
int_value: .res 2

.code
;parses a string, returns integer (up to 16 bits)
;inputs: AX points to a string containing an integer
;outputs: AX contains integer
parse_integer:
      
  stax  target_string
  lda #0
  sta int_value
  sta int_value+1
  tay
@parse_int:
  lda (target_string),y
  cmp #$30
  bcc @end_of_int  ;any non-decimal char should be treated as end of integer   
  cmp #$39
  bcs @end_of_int  ;any non-decimal char should be treated as end of integer 
   
  ldax  int_value
  stax  acc16
  lda #10
  jsr mul_8_16
  ldax  acc16
  stax  int_value
  lda (target_string),y
  sec
  sbc #'0'
  clc
  adc int_value
  sta int_value
  bcc @no_rollover  
  inc int_value+1
@no_rollover:
  iny
  bne @parse_int
@end_of_int:
  ldax int_value
  clc
  rts
