  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
    
  .import cfg_get_configuration_ptr 
	.import copymem
	.importzp copy_src
	.importzp copy_dest
  .import exit_to_basic  
  
  
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__ 
  .import  __DATA_SIZE__
  .import __IP65_DEFAULTS_SIZE__
.segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-$03                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+__IP65_DEFAULTS_SIZE__+4	; file size
        jmp init

.code

init:
cld
  jsr print_cr
  init_ip_via_dhcp 
  jsr print_ip_config
  jsr print_cr
  jmp exit_to_basic
  