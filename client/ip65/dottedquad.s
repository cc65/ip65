
  .include "../inc/common.i"
 
  
  .export parse_dotted_quad
  .export dotted_quad_value
  
	.bss
  dotted_quad_value: .res 4 ;set to 32 bit ip address on a succesful call to parse_dotted_quad
  
  dotted_quad_ptr:  .res 4
  
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
    
    lda #$AD  ; $AD='LDA immediate'
    sta dotted_quad_ptr 

    lda #$60  ; $60='RTS
    sta dotted_quad_ptr+3 
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