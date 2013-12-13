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



;-- LICENSE FOR parser.s --
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
