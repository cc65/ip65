; #############
; 
; This will boot a C64 with an RR-NET compatible cs8900a  from the network
; requires
; 1) a DHCP server, and
; 2) a TFTP server that responds to requests on the broadcast address (255.255.255.255) and that will serve a file called 'BOOTC64.PRG'.
; the prg file can be either BASIC or M/L, and up to 22K in length.
;
; jonno@jamtronix.com - January 2009
;

;possible bankswitch values are:
;$00 = no bankswitching (i.e. NB65 API in RAM only)
;$01 = standard bankswitching (via HIRAM/LORAM)
;$02 = advanced bankswitching (via custom registers, e.g. $de00 on the Retro Replay cart)

.ifndef BANKSWITCH_SUPPORT
  .error "must define BANKSWITCH_SUPPORT"
  
.endif 

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

  .macro nb65call arg
    ldy arg
    jsr NB65_DISPATCH_VECTOR
  .endmacro

.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif
  .include "../inc/common.i"
  .include "../inc/c64keycodes.i"
  .include "../inc/menu.i"
  
  .import cls
  .import beep
  .import exit_to_basic
  .import timer_vbl_handler
  .import nb65_dispatcher
  .import ip65_process
  .import get_filtered_input
  .import filter_text
  .import filter_dns
  .import print_arp_cache

  .import print_dotted_quad
  .import print_hex
  .import print_ip_config
  .import ok_msg
  .import failed_msg
  .import init_msg
  .import print_a
  .import print_cr
  .import print
	.import copymem
	.importzp copy_src
	.importzp copy_dest
  .import get_filtered_input
  .import  __DATA_LOAD__
  .import  __DATA_RUN__
  .import  __DATA_SIZE__
  .import cfg_tftp_server
  tftp_dir_buffer = $6000
  
  .data
exit_cart:
.if (BANKSWITCH_SUPPORT=$02)
  lda #$02    
  sta $de00   ;turns off RR cartridge by modifying GROUND and EXROM
.elseif (BANKSWITCH_SUPPORT=$01)
  lda #$36
  sta $0001   ;turns off ordinary cartridge by modifying HIRAM/LORAM (this will also bank out BASIC)
.endif

call_downloaded_prg: 
   jsr $0000 ;overwritten when we load a file
   jmp init
   
	.bss

nb65_param_buffer: .res $20


.segment "CARTRIDGE_HEADER"
.word init  ;cold start vector
.word $FE47  ;warm start vector
.byte $C3,$C2,$CD,$38,$30 ; "CBM80"
.byte $4E,$42,$36,$35  ; "NB65"  - API signature
.byte $01 ;NB65_API_VERSION
.byte BANKSWITCH_SUPPORT ;
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


  ;set some funky colours
  LDA #$05  ;green
  STA $D020 ;background
  LDA #$00  ;black 
  STA $D021 ;background
  lda #$1E
  jsr print_a

;relocate our r/w data
  ldax #__DATA_LOAD__
  stax copy_src
  ldax #__DATA_RUN__
  stax copy_dest
  ldax #__DATA_SIZE__
  jsr copymem

;copy the RAM stub to RAM
  ldax #nb65_ram_stub
  stax copy_src
  ldax #NB65_RAM_STUB_SIGNATURE
  stax copy_dest
  ldax #nb65_ram_stub_length
  jsr copymem

;if this is a 'normal' cart then we will end up swapping BASIC out, so copy it to the RAM under ROM
.if (BANKSWITCH_SUPPORT=$01)
  ldax #$A000
  stax copy_src
  stax copy_dest
  ldax #$2000
  jsr copymem
.endif  
  
ldax #init_msg
	jsr print
  
  nb65call #NB65_INITIALIZE
  
main_menu:
  jsr cls  
  ldax  #netboot65_msg
  jsr print
  ldax  #main_menu_msg
  jsr print
  jsr print_ip_config
  jsr print_cr
  
@get_key:
  jsr get_key
  cmp #KEYCODE_F1
  bne @not_tftp
  jmp @tftp_boot
 @not_tftp:  
  cmp #KEYCODE_F3    
  beq @exit_to_basic
  cmp #KEYCODE_F5 
  beq @util_menu
  cmp #KEYCODE_F7
  beq @change_config
  
  jmp @get_key

@exit_to_basic:
  ldax #$fe66 ;do a wam start
  jmp exit_cart_via_ax

@util_menu_header:
  jsr cls  
  ldax  #netboot65_msg
  jsr print
  ldax  #util_menu_msg
  jsr print
  rts
@util_menu:
  jsr @util_menu_header
@get_key_util_menu:
  jsr get_key
  cmp #KEYCODE_F1
  bne @not_arp_cache
  jsr @util_menu_header
  jsr print_arp_cache
  jmp @get_key_util_menu
 @not_arp_cache:
  cmp #KEYCODE_F7
  beq main_menu
  jmp @get_key_util_menu


@change_config:
  jsr cls  
  ldax  #netboot65_msg
  jsr print
  ldax  #config_menu_msg
  jsr print
  ldax #current
  jsr print
  ldax #tftp_server
  jsr print
  ldax #cfg_tftp_server
  jsr print_dotted_quad
  jsr print_cr
  ldax #enter_new_tftp_server
  jsr print
  jsr print_cr
  ldax #filter_dns
  jsr get_filtered_input
  bcs @no_server_entered
  stax nb65_param_buffer 
  jsr print_cr  
  ldax #resolving
  jsr print
  ldax #nb65_param_buffer
  nb65call #NB65_DNS_RESOLVE  
  bcs @resolve_error  
  ldax #nb65_param_buffer
  stax copy_src
  ldax #cfg_tftp_server
  stax copy_dest
  ldax #4
  jsr copymem
@no_server_entered:  
  jmp main_menu

@resolve_error:
  print_failed
  jsr wait_for_keypress
  jmp main_menu
  
@tftp_boot:  

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
  nb65call #NB65_TFTP_DIRECTORY_LISTING  
  
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
  bcc @tftp_filename_set
  lda #21 ;switch back to upper case
  sta $d018
  jmp main_menu
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
  
  ;get ready to bank out
  nb65call #NB65_DEACTIVATE   
  
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
  jmp exit_cart_via_ax
  
@not_a_basic_file:  
  ldax  nb65_param_buffer+NB65_TFTP_POINTER
exit_cart_via_ax:  
  sta call_downloaded_prg+1
  stx call_downloaded_prg+2
  
  jmp exit_cart

print_errorcode:
  ldax #error_code
  jsr print
  nb65call #NB65_GET_LAST_ERROR
  jsr print_hex
  jmp print_cr
  

setup_param_buffer_for_tftp_call:
  
  ldx #3
  lda cfg_tftp_server,x
: 
  sta nb65_param_buffer+NB65_TFTP_IP,x
  dex
  bpl :-
  rts

bad_boot:
  jsr wait_for_keypress
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
  ldax #nb65_param_buffer
  nb65call #NB65_TFTP_DOWNLOAD
  
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

wait_for_keypress:
  ldax  #press_a_key_to_continue
  jsr print
@loop:  
  jsr $ffe4
  beq @loop
  rts

get_key:
@loop:  
  jsr NB65_PERIODIC_PROCESSING_VECTOR
  jsr $ffe4
  beq @loop
  rts


cfg_get_configuration_ptr:
  ldax #nb65_param_buffer  
  nb65call #NB65_GET_IP_CONFIG
  rts
  
	.rodata

netboot65_msg: 
.byte "NETBOOT65 - C64 NETWORK BOOT CLIENT V0.4",13
.byte 0
main_menu_msg:
.byte "F1: TFTP BOOT        F3: BASIC",13
.byte "F5: UTILITIES        F7: CONFIG",13,13
.byte 0

util_menu_msg:
.byte "F1: ARP TABLE",13
.byte "                     F7: MAIN MENU",13,13
.byte 0

config_menu_msg:
.byte "NETBOOT65 CONFIGURATION",13,0

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

current:
.byte "CURRENT ",0
enter_new_tftp_server:
.byte"ENTER "

new_tftp_server:
  .byte "NEW "
tftp_server:  
.byte "TFTP SERVER: ",0
  
tftp_dir_filemask:  
  .asciiz "*.PRG"

tftp_file:  
  .asciiz "BOOTC64.PRG"

no_files_on_server:
  .byte "TFTP SERVER HAS NO MATCHING FILES",13,0

press_a_key_to_continue:
  .byte "PRESS A KEY TO CONTINUE",13,0

resolving:
  .byte "RESOLVING ",0

nb65_ram_stub: ; this gets copied to $C000 so programs can bank in the cartridge
.byte $4E,$42,$36,$35  ; "NB65"  - API signature
  
.if (BANKSWITCH_SUPPORT=$02)
  lda #$01    
  sta $de00   ;turns on RR cartridge (since it will have been banked out when exiting to BASIC)
.elseif (BANKSWITCH_SUPPORT=$01)
  lda #$37
  sta $0001   ;turns on ordinary cartridge by modifying HIRAM/LORAM (this will also bank in BASIC)
.endif

  rts
nb65_ram_stub_end:
nb65_ram_stub_length=nb65_ram_stub_end-nb65_ram_stub