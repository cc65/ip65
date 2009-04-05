; #############
; 
; This will boot a C64 with RR-NET from the network
; requires
; 1) a DHCP server, and
; 2) a TFTP server that responds to requests on the broadcast address (255.255.255.255) and that will serve a file called 'BOOTC64.PRG'.
; the prg file can be either BASIC or M/L, and up to 22K in length.
;
; jonno@jamtronix.com - January 2009
;


  .macro print_failed
    ldax #failed_msg
    jsr print
    jsr print_cr
  .endmacro

  .macro print_ok
    ldax #ok_msg
    jsr print
    jsr print_cr
  .endmacro


  .include "../inc/nb65_constants.i"
  .include "../inc/common.i"
  .include "../inc/menu.i"
  .include "../inc/c64keycodes.i"
  
  .import cls
  .import get_key
  .import beep
  .import exit_to_basic
  .import timer_vbl_handler
  .import nb65_dispatcher
  .import ip65_process

  .import print_hex
  .import print_ip_config
  .import dhcp_msg
  .import ok_msg
  .import failed_msg
  .import init_msg
  .import print_a
  .import print_cr
  .import print
	.import copymem
	.importzp copy_src
	.importzp copy_dest

  .import  __DATA_LOAD__
  .import  __DATA_RUN__
  .import  __DATA_SIZE__

  tftp_dir_buffer = $6000
  
  .data
exit_cart:
  lda #$02    
  sta $de00   ;turns off RR cartridge - obviously we need to execut this from RAM else we fall into never-never land :-)
jmp_to_downloaded_prg: 
    jmp $0000 ;overwritten when we load a file
   
	.bss

nb65_param_buffer: .res $20


.segment "CARTRIDGE_HEADER"
.word init  ;cold start vector
.word $FE47  ;warm start vector
.byte $C3,$C2,$CD,$38,$30 ; "CBM80"
.byte "NB65"  ;netboot 65 signature
jmp nb65_dispatcher    ; NB65_DISPATCH_VECTOR   : entry point for NB65 functions
jmp ip65_process          ;NB65_PERIODIC_PROCESSING_VECTOR : routine to be periodically called to check for arrival of ethernet packects
jmp timer_vbl_handler     ;NB65_VBL_VECTOR : routine to be called during each vertical blank interrupt

  
.code

  
  
init:
  
  ;first let the kernal do a normal startup
  sei
  jsr $fda3   ;initialize CIA I/O
  jsr $fd50   ;RAM test, set pointers
  jsr $fd15   ;set vectors for KERNAL
  jsr $ff5B   ;init. VIC
  cli         ;KERNAL init. finished
  jsr $e453   ;set BASIC vectors
  jsr $e3bf   ;initialize zero page




;relocate our r/w data
  ldax #__DATA_LOAD__
  stax copy_src
  ldax #__DATA_RUN__
  stax copy_dest
  ldax #__DATA_SIZE__
  jsr copymem


  ldax  #startup_msg 
  jsr print

@get_key:
  jsr get_key
  cmp #KEYCODE_F1
  beq @tftp_boot
  cmp #KEYCODE_F3
    
  beq @exit_to_basic
  
  jmp @get_key

@exit_to_basic:
  ldax #$fe66 ;do a wam start
  jmp exit_to_cart_via_ax

@tftp_boot:  

  ldy #NB65_GET_DRIVER_NAME
  jsr NB65_DISPATCH_VECTOR 
  jsr print
  ldax #init_msg
	jsr print
  
  ldy #NB65_INIT_IP
  jsr NB65_DISPATCH_VECTOR 

	bcc :+  
  print_failed
  jsr print_errorcode
  jmp bad_boot    
:
  
  print_ok
  
  ldax #dhcp_msg
  jsr print
  ldax #init_msg
	jsr print
  
  ldy #NB65_INIT_DHCP
  jsr NB65_DISPATCH_VECTOR 
	bcc :+  
	print_failed
  jsr print_errorcode  
  jmp bad_boot
:
  print_ok

  jsr print_ip_config

  ldax  #press_a_key_to_continue
  jsr print
  jsr get_key

  jsr setup_param_buffer_for_tftp_call
  
  ldax #tftp_dir_buffer
  stax nb65_param_buffer+NB65_TFTP_POINTER

  ldax #getting_dir_listing_msg
	jsr print

  ldax #tftp_dir_filemask
  stax nb65_param_buffer+NB65_TFTP_FILENAME

  jsr print
  jsr print_cr

  ldax  #nb65_param_buffer
  ldy #NB65_TFTP_DIRECTORY_LISTING
  jsr NB65_DISPATCH_VECTOR 
  
	bcs @dir_failed

  lda tftp_dir_buffer ;get the first byte that was downloaded
  bne :+
  jmp @no_files_on_server
:  

  ;switch to lower case charset
  lda #23
  sta $d018


  ldax  #tftp_dir_buffer
  
  jsr select_option_from_menu  

@tftp_filename_set:
  jsr download
  bcc @file_downloaded_ok
  jmp bad_boot
  
@dir_failed:  
  ldax  #tftp_dir_listing_fail_msg
  jsr print
  jsr print_errorcode
  jsr print_cr
  
  ldax #tftp_file
  jmp @tftp_filename_set
  
@no_files_on_server:
  ldax #no_files_on_server
	jsr print

  jmp bad_boot
  
@file_downloaded_ok:  
  
  ;remove the IP timer code from IRQ chain
  ldy #NB65_UNHOOK_VBL_IRQ
  jsr NB65_DISPATCH_VECTOR
  
  ;check whether the file we just downloaded was a BASIC prg
  lda nb65_param_buffer+NB65_TFTP_POINTER
  cmp #01
  bne @not_a_basic_file
  lda nb65_param_buffer+NB65_TFTP_POINTER+1
  cmp #$08
  bne @not_a_basic_file

  jsr $e453 ;set BASIC vectors 
  jsr $e3bf ;initialize BASIC 
  jsr $a86e 
  jsr $a533  ; re-bind BASIC lines 
  ldx $22    ;load end-of-BASIC pointer (lo byte)
  ldy $23    ;load end-of-BASIC pointer (hi byte)
  stx $2d    ;save end-of-BASIC pointer (lo byte)
  sty $2e    ;save end-of-BASIC pointer (hi byte)
  jsr $a659  ; CLR (reset variables)
  ldax  #$a7ae  ; jump to BASIC interpreter loop   
  jmp exit_to_cart_via_ax
  
@not_a_basic_file:  
  ldax  nb65_param_buffer+NB65_TFTP_POINTER
exit_to_cart_via_ax:  
  stax jmp_to_downloaded_prg+1
  jmp exit_cart

print_errorcode:
  ldax #error_code
  jsr print
  ldy #NB65_GET_LAST_ERROR
  jsr NB65_DISPATCH_VECTOR
  jsr print_hex
  jmp print_cr
  

setup_param_buffer_for_tftp_call:
  
  ldx #3
  lda #$ff    ;255.255.255.255 = broadcast address
: 
  sta nb65_param_buffer+NB65_TFTP_IP,x
  dex
  bpl :-
  rts

bad_boot:
  ldax  #press_a_key_to_continue
  jsr print
  jsr get_key
  jmp $fe66   ;do a wam start

download: ;AX should point at filename to download
  stax nb65_param_buffer+NB65_TFTP_FILENAME
  ldax #$0000   ;load address will be first 2 bytes of file we download (LO/HI order)
  stax nb65_param_buffer+NB65_TFTP_POINTER

  ldax #downloading_msg
	jsr print
  ldax nb65_param_buffer+NB65_TFTP_FILENAME
  jsr print  
  jsr print_cr
  
  jsr setup_param_buffer_for_tftp_call
  ldy #NB65_TFTP_DOWNLOAD
  ldax #nb65_param_buffer
  jsr NB65_DISPATCH_VECTOR 
	bcc :+
  
	ldax #tftp_download_fail_msg  
	jsr print
  jsr print_errorcode
  sec
  rts
  
:
  ldax #tftp_download_ok_msg
	jsr print
  clc
  rts

cfg_get_configuration_ptr:
  ldy #NB65_GET_IP_CONFIG_PTR
  ldax #nb65_param_buffer  
  jmp NB65_DISPATCH_VECTOR 
  
	.rodata

startup_msg: 
.byte "NETBOOT65 - C64 NETWORK BOOT CLIENT V0.3",13
.byte "F1=TFTP BOOT, F3=BASIC",13
.byte 0

downloading_msg:  .asciiz "DOWNLOADING "

getting_dir_listing_msg: .asciiz "FETCHING TFTP DIRECTORY FOR "

tftp_dir_listing_fail_msg:
	.byte "DIR LISTING FAILED",13,0

tftp_download_fail_msg:
	.byte "DOWNLOAD FAILED", 13, 0

tftp_download_ok_msg:
	.byte "DOWNLOAD OK", 13, 0
  
error_code:  
  .asciiz "ERROR CODE: "

tftp_dir_filemask:  
  .asciiz "*.PRG"

tftp_file:  
  .asciiz "BOOTC64.PRG"

no_files_on_server:
  .byte "TFTP SERVER HAS NO MATCHING FILES",13,0

press_a_key_to_continue:
  .byte "PRESS A KEY TO CONTINUE",13,0
