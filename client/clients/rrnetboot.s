;#############
; 
; This will boot a C64 with RR-NET from the network
; requires
; 1) a DHCP server, and
; 2) a TFTP server that responds to requests on the broadcast address (255.255.255.255) and that will serve a file called 'BOOTC64.PRG'.
; the prg file can be either BASIC or M/L, and up to 22K in length.
;
; jonno@jamtronix.com - January 2009
;

RRNETBOOT_IP65_DISPATCHER = $800d 
RRNETBOOT_IP65_PROCESS =$8010
RRNETBOOT_IP65_VBL =$8013



  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/menu.i"
  .include "../inc/net.i"
  .include "../inc/c64keycodes.i"
  .include "../inc/ip65_function_numbers.i"
  .import cls
  .import get_key
  .import beep
  .import exit_to_basic
  .import timer_vbl_handler
  .import ip65_dispatcher
  .import ip65_process

  .importzp tftp_filename
  .import tftp_load_address
  .import tftp_ip
  .import tftp_download
  .import tftp_directory_listing 
  .import tftp_set_download_callback
  
	.import copymem
	.importzp copy_src
	.importzp copy_dest

  .import  __DATA_LOAD__
  .import  __DATA_RUN__
  .import  __DATA_SIZE__

	.bss

;temp_bin: .res 1
;temp_bcd: .res 2

bin_file_jmp: .res 3
tftp_dir_buffer: .res 2000


.segment "CARTRIDGE_HEADER"
.word init  ;cold start vector
.word init  ;warm start vector
.byte $C3,$C2,$CD,$38,$30 ; "CBM80"
.byte "NB65"  ;netboot 65 signature
jmp ip65_dispatcher    ; RRNETBOOT_IP65_DISPATCHER   : entry point for IP65 functions
jmp ip65_process          ;RRNETBOOT_IP65_PROCESS : routine to be periodically called to check for arrival of ethernet packects
jmp timer_vbl_handler     ;RRNETBOOT_IP65_VBL : routine to be called during each vertical blank interrupt

.data
jmp_old_irq:
  jmp $0000
  
.code

  

irq_handler:
  jsr RRNETBOOT_IP65_VBL
  jmp jmp_old_irq

remove_irq_handler:
  ldax  jmp_old_irq+1  ;previous IRQ handler
  sei ;don't want any interrupts while we fiddle with the vector
  stax  $314   
  cli
  rts
  
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

;install our IRQ handler
  ldax  $314    ;previous IRQ handler
  stax  jmp_old_irq+1
  sei ;don't want any interrupts while we fiddle with the vector
  ldax #irq_handler
  stax  $314    ;previous IRQ handler
  cli

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
  jsr remove_irq_handler
  jmp $fe66   ;do a wam start

@tftp_boot:  

print_driver_init
  ldy #FN_IP65_INIT
  jsr RRNETBOOT_IP65_DISPATCHER 

	bcc :+
  print_failed
  jmp bad_boot    
:
  
  print_ok
  
  print_dhcp_init
  
  ldy #FN_DHCP_INIT
  jsr RRNETBOOT_IP65_DISPATCHER 
	bcc :+  
	print_failed
  jmp bad_boot
:
  print_ok

  jsr print_ip_config

    ldx #3
: 
  lda cfg_tftp_server,x
  sta tftp_ip,x
  dex
  bpl :-

  ldax  #press_a_key_to_continue
  jsr print
  jsr get_key


  ldax #tftp_dir_buffer
  stax tftp_load_address

  ldax #getting_dir_listing_msg
	jsr print

  ldax #tftp_dir_filemask
  stax tftp_filename
  jsr print
  jsr print_cr

  jsr tftp_directory_listing 
	bcs @dir_failed

  lda tftp_dir_buffer ;get the first byte that was downloaded
  bne :+
  jmp @no_files_on_server
:  
  ldax #$0000   ;load address will be first 2 bytes of file we dowload (LO/HI order)
  stax tftp_load_address

  ;switch to lower case charset
  lda #23
  sta $d018
  ldax  #tftp_dir_buffer
  
  jsr select_option_from_menu  
  stax tftp_filename


  ldax #downloading_msg
	jsr print


  ldax tftp_filename
  jsr download
  bcc @file_downloaded_ok
  
@dir_failed:  
  ldax  #tftp_dir_listing_fail_msg
  jsr print
  
  ldax #$0000   ;load address will be first 2 bytes of file we download (LO/HI order)
  stax tftp_load_address

  ldax #downloading_msg
	jsr print

  ldax #tftp_file
  jsr download
  
  bcc @file_downloaded_ok
  jmp bad_boot
  
@no_files_on_server:
  ldax #no_files_on_server
	jsr print

  jmp bad_boot
  
@file_downloaded_ok:  

  jsr remove_irq_handler  
                          ;check whether the file we just downloaded was a BASIC prg
  lda tftp_load_address
  cmp #01
  bne @not_a_basic_file
  lda tftp_load_address+1
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
  jmp $a7ae  ; jump to BASIC interpreter loop 
  
@not_a_basic_file:  
  lda #$4C  ;opcode for JMP
  sta bin_file_jmp
  ldax  tftp_load_address
  stax bin_file_jmp+1
  jsr bin_file_jmp
  rts


bad_boot:
  ldax  #press_a_key_to_continue
  jsr print
  jsr get_key
  jsr remove_irq_handler
  jmp $fe66   ;do a wam start

download:
  stax tftp_filename
  jsr print
  jsr print_cr

  jsr tftp_download  
	bcc :+
  
	ldax #tftp_download_fail_msg
	jsr print
  sec
  rts
  
:
  ldax #tftp_download_ok_msg
	jsr print
  clc
  rts
  
	.rodata

startup_msg: 
.byte "NETBOOT65 - C64 NETWORK BOOT CLIENT V0.2",13
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
  
tftp_dir_filemask:  
  .asciiz "*.PRG"

tftp_file:  
  .asciiz "BOOTC64.PRG"

no_files_on_server:
  .byte "TFTP SERVER HAS NO MATCHING FILES",13,0

press_a_key_to_continue:
  .byte "PRESS A KEY TO CONTINUE",13,0
