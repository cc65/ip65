  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/a2const.i"
  .import exit_to_basic  
  .import cfg_get_configuration_ptr


  
  .import copymem
  .importzp copy_src
  .importzp copy_dest
  
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__ 
  .import  __DATA_SIZE__
  .import __IP65_DEFAULTS_SIZE__
  .import __BSS_RUN__ 
  .import __BSS_SIZE__ 
  
 END_OF_BSS =  __BSS_RUN__+__BSS_SIZE__ 

.segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-$03                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+__IP65_DEFAULTS_SIZE__+4	; file size
        jmp init
.code

init:

	
	ldax #END_OF_BSS
	stax TXTTAB
    print_hex_double #END_OF_BSS
	ldax #start_message
	jsr	print
	ldax #amper_handler
	stax  AMPERSAND_VECTOR+1
	jsr	SCRTCH
	jmp exit_to_basic
	
	
start_message: .byte "AMPER ON ALES",13,0

amper_handler:
	lda #'*'
	jmp	print_a
	