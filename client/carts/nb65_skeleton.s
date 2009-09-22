;use the NB65 API to send a d64 disk via TFTP

.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif

.include "../ip65/copymem.s"
.include "../inc/common.i"

.import print_a
.import get_key
.macro cout arg
  lda arg
  jsr print_a
.endmacro   
    
  .zeropage
  temp_ptr:		.res 2
  
  .bss
  nb65_param_buffer: .res $20  
  block_number: .res $0
  
.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

.word basicstub		; load address

.macro print arg
  ldax arg
	ldy #NB65_PRINT_ASCIIZ
  jsr NB65_DISPATCH_VECTOR 
.endmacro 

.macro print_cr
  lda #13
	jsr print_a
.endmacro

.macro call arg
	ldy arg
  jsr NB65_DISPATCH_VECTOR   
.endmacro

basicstub:
	.word @nextline
	.word 2003
	.byte $9e 
	.byte <(((init / 1000) .mod 10) + $30)
	.byte <(((init / 100 ) .mod 10) + $30)
	.byte <(((init / 10  ) .mod 10) + $30)
	.byte <(((init       ) .mod 10) + $30)
	.byte 0
@nextline:
	.word 0


;look for NB65 signature at location pointed at by AX
look_for_signature: 
  stax temp_ptr
  ldy #3
@check_one_byte:
  lda (temp_ptr),y
  cmp nb65_signature,y
  bne @bad_match  
  dey 
  bpl@check_one_byte  
  clc
  rts
@bad_match:
  sec
  rts
init:

  print #signon_message

  ldax #NB65_CART_SIGNATURE  ;where signature should be in cartridge
  jsr  look_for_signature
  bcc @found_nb65_signature

  ldax #NB65_RAM_STUB_SIGNATURE  ;where signature should be in RAM
  jsr  look_for_signature
  bcc :+
  jmp nb65_signature_not_found
:  
  jsr NB65_RAM_STUB_ACTIVATE     ;we need to turn on NB65 cartridge
  
@found_nb65_signature:

  print #initializing
  print #nb65_signature
  ldy #NB65_INITIALIZE
  jsr NB65_DISPATCH_VECTOR 
	bcc :+  
  print #failed
  jsr print_errorcode
  jmp bad_boot    
:  
  print #ok
  print_cr
    
; ######################## 
; main program goes here:
; 
  rts

bad_boot:
  print  #press_a_key_to_continue
restart:    
  jsr get_key
  jmp $fce2   ;do a cold start


print_errorcode:
  print #error_code
  call #NB65_GET_LAST_ERROR
  call #NB65_PRINT_HEX
  print_cr
  rts

nb65_signature_not_found:

  ldy #0
:
  lda nb65_signature_not_found_message,y
  beq restart
  jsr print_a
  iny
  jmp :-

.rodata

error_code:  
  .asciiz "ERROR CODE: $"
press_a_key_to_continue:
  .byte "PRESS A KEY TO CONTINUE",13,0

failed:
	.byte "FAILED ", 0

ok:
	.byte "OK ", 0
  
initializing:  
  .byte "INITIALIZING ",0

signon_message:
  .byte "NB65 UNNAMED TOOL V0.1",13,0
  
 nb65_signature_not_found_message:
 .byte "NO NB65 API FOUND",13,"PRESS ANY KEY TO RESET", 0
 
nb65_signature:
  .byte $4E,$42,$36,$35  ; "NB65"  - API signature
  .byte ' ',0 ; so we can use this as a string