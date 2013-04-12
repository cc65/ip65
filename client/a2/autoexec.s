  .include "../inc/common.i"
  .include "../inc/a2const.i"
  .import exit_to_basic  
  
  
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__ 
  .import  __DATA_SIZE__

.segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-$03                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; file size
        jmp init

.code

init:
	lday #chain_cmd
	jsr STROUT
  
  jmp exit_to_basic
  chain_cmd:
  .byte 13,4,"CATALOG",13,0