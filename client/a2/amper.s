  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/a2const.i"
  .include "../inc/net.i"
  
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


  ;BASIC keywords installed, now bring up the ip65 stack
    
	jsr ip65_init
  	bcc @init_ok
  	ldax #@no_nic
  	jsr	print
@reboot:  
	jmp exit_to_basic
@no_nic:
  .byte "NO NETWORK CARD FOUND - UNINSTALLING",0  
@install_msg:
  .byte " FOUND",13,"APPLESOFT ON ALES IN $801-$"

  .byte 0
@init_ok:
	;print the banner
  	ldax #eth_driver_name
  	jsr print_ascii_as_native
	ldax #@install_msg
	jsr	print	
	print_hex_double #END_OF_BSS	
    jsr	print_cr  
    
    ;take over the ampersand vector
    ldax AMPERSAND_VECTOR+1
    stax old_amper_handler		
	ldax #amper_handler
	stax  AMPERSAND_VECTOR+1

	ldax #END_OF_BSS
	stax TXTTAB
	jsr	SCRTCH		;reset BASIC now we have updated the start address 
		
	jmp exit_to_basic
	
amper_handler:
		

exit_to_old_handler:
	jmp	$ffff
old_amper_handler=exit_to_old_handler+1
	
	lda #'*'
	jmp	print_a
	

	