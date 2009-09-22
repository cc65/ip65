;text file parsing routines
; first call parser_init
; then call parser_skip_next

.export parser_init
.export parser_skip_next
.importzp copy_src
.importzp copy_dest


target_string=copy_src
search_string=copy_dest

.include "../inc/common.i"
.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.bss
temp_ptr: .res 2

.segment "SELF_MODIFIED_CODE"
get_next_byte:
current_string_ptr=get_next_byte+1
  lda $ffff
  inc current_string_ptr
  bne :+
  inc current_string_ptr+1
:  
  pha
  pla ;reload A so flags are set correctly
  rts

.code

;set up a string for parsing
;inputs: AX = pointer to (null terminated) string to be parsed
;outputs: none
parser_init:
  stax current_string_ptr
  clc
  rts
 

;advance pointer along till just past the next occurance of specified string
;inputs: AX= pointer to (null terminated) string to search for 
;outputs: sec if search string not found
; if clc, AX = pointer to first byte after string specified 
; if sec (i.e. no match found), pointer stays in same place
parser_skip_next:
  stax  search_string
  ldax  current_string_ptr
  stax temp_ptr
@check_string:
  ldy #0
  ldax  current_string_ptr
  stax target_string
@check_next_char:
  lda (search_string),y
  beq @matched  
  cmp (target_string),y
  bne @not_matched
  iny
  bne @check_next_char
@matched:
  ;now skip 'y' bytes

@skip_byte:
  jsr get_next_byte
  dey 
  bne @skip_byte  

  ldax current_string_ptr
  clc
  rts
 @not_matched:
  jsr get_next_byte
  bne @check_string
  ldax  temp_ptr
  stax current_string_ptr
  sec
  rts
