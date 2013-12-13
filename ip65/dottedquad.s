
  .include "../inc/common.i"
 
  
  .export parse_dotted_quad
  .export dotted_quad_value
  
	.bss
  dotted_quad_value: .res 4 ;set to 32 bit ip address on a succesful call to parse_dotted_quad
  
  .data
  
  ;self modifying code
  dotted_quad_ptr:
  lda $FFFF
  rts
    
  
	.code


; convert a string representing a dotted quad (IP address, netmask) into 4 octets
; inputs:
;   AX= pointer to null-terminated (*) string containing dotted quad
;         e.g. "192.168.1.0",0
; outputs:
;   carry flag is set if there was an error, clear otherwise
;   dotted_quad_value: will be set to (32 bit) ip address (if no error)
; (*) NB to assist with url parsing, a ':' or '/' can also terminate the string
parse_dotted_quad:
    stax  dotted_quad_ptr+1    
    ldx #0
    txa 
    sta dotted_quad_value
@each_byte:  
    jsr get_next_byte
    cmp #0
    beq @done
    and #$7F  ;turn off bit 7
    cmp #'.'
    beq @got_dot
    cmp #':'
    beq @done
    cmp #'/'
    beq @done
    sec
    sbc #'0'
    bcc @error
    cmp #10
    bcs @error
  
    clc
    ldy	#10
@mul_by_y:
    adc dotted_quad_value,x
    bcs @error
    dey
    bne @mul_by_y	
    sta dotted_quad_value,x
    jmp @each_byte
    
@got_dot:
  inx
  cpx #4
  beq @error
  lda #0
  sta dotted_quad_value,x
  jmp @each_byte
@done:
    cpx #3
    bne @error
    clc
    rts
@error:   
    sec
    rts


get_next_byte:
    jsr dotted_quad_ptr
    inc dotted_quad_ptr+1
    bne :+
    inc dotted_quad_ptr+2
:
    rts


;-- LICENSE FOR dottedquad.s --
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
