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
;$01 = 8KB image with standard bankswitching (via HIRAM/LORAM)
;$02 = 8KB image with advanced bankswitching (via custom registers, e.g. $de00 on the Retro Replay cart)
;$03 = 16KB image with standard bankswitching (via HIRAM/LORAM) - BASIC is NOT avialable
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

.if (BANKSWITCH_SUPPORT=$03)

  KEY_NEXT_PAGE=KEYCODE_F7
  KEY_PREV_PAGE=KEYCODE_F1
  KEY_SHOW_HISTORY=KEYCODE_F2
  KEY_BACK_IN_HISTORY=KEYCODE_F3
  KEY_NEW_SERVER=KEYCODE_F5

  
  .include "../inc/gopher.i"
  .include "../inc/telnet.i"
.endif
  .import cls
  .import beep
  .import exit_to_basic
  .import timer_vbl_handler
  .import nb65_dispatcher
  .import ip65_process
  .import ip65_init
  .import get_filtered_input
  .import filter_text
  .import filter_dns
  .import filter_ip
  .import print_arp_cache
  .import arp_calculate_gateway_mask
  .import parse_dotted_quad
  .import dotted_quad_value
   
  .import get_key_ip65   
  .import cfg_ip
	.import cfg_netmask
	.import cfg_gateway
	.import cfg_dns
  .import cfg_tftp_server
  
  .import print_dotted_quad
  .import print_hex
  .import print_errorcode
  .import print_ip_config
  .import ok_msg
  .import failed_msg
  .import init_msg
  .import ip_address_msg
  .import netmask_msg
  .import gateway_msg
  .import dns_server_msg
  .import tftp_server_msg
 
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
  tftp_dir_buffer = $6020
 nb65_param_buffer = $6000

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
   
get_value_of_axy: ;some more self-modifying code
	lda $ffff,y
  rts


.segment "CARTRIDGE_HEADER"
.word init  ;cold start vector
.word $FE47  ;warm start vector
.byte $C3,$C2,$CD,$38,$30 ; "CBM80"
.byte $4E,$42,$36,$35  ; "NB65"  - API signature
.if (BANKSWITCH_SUPPORT=$03)
.byte $02 ;NB65_API_VERSION 2 requires 16KB cart
.else
.byte $01 ;NB65_API_VERSION 1 (in an 8KB cart)
.endif
.byte BANKSWITCH_SUPPORT ;
jmp nb65_dispatcher    ; NB65_DISPATCH_VECTOR   : entry point for NB65 functions
jmp ip65_process          ;NB65_PERIODIC_PROCESSING_VECTOR : routine to be periodically called to check for arrival of ethernet packets
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
.if (BANKSWITCH_SUPPORT=$03)
  LDA #$04  ;purple
  .else
  LDA #$05  ;green
  .endif

  STA $D020 ;border
  LDA #$00  ;black 
  STA $D021 ;background
  .if (BANKSWITCH_SUPPORT=$03)
  lda #$9c  ;petscii for purple text  
  .else
  lda #$1E  ;petscii for green text
  .endif
  lda #$05  ;petscii for white text
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
  bcc main_menu
  print_failed
  jsr print_errorcode
  jsr wait_for_keypress  
  jmp exit_to_basic

print_main_menu:
  lda #21 ;make sure we are in upper case
  sta $d018
  jsr cls  
  ldax  #netboot65_msg
  jsr print
  ldax  #main_menu_msg
  jmp print

main_menu:
  jsr print_main_menu
  jsr print_ip_config
  jsr print_cr
  
@get_key:
  jsr get_key_ip65
  cmp #KEYCODE_F1
  bne @not_tftp
  jmp @tftp_boot
 @not_tftp:  

  cmp #KEYCODE_F3      
  .if (BANKSWITCH_SUPPORT=$03)
  bne @not_f3
  jmp net_apps_menu
  .else
  beq @exit_to_basic    
.endif  
@not_f3:
  cmp #KEYCODE_F5 
  bne @not_util_menu
  jsr print_main_menu
  jsr print_arp_cache
  jmp @get_key
@not_util_menu:
  cmp #KEYCODE_F7
  beq @change_config
  
  jmp @get_key

@exit_to_basic:
  ldax #$fe66 ;do a wam start
  jmp exit_cart_via_ax


@change_config:
  jsr cls  
  ldax  #netboot65_msg
  jsr print
  ldax  #config_menu_msg
  jsr print
  jsr print_ip_config
  jsr print_cr
@get_key_config_menu:  
  jsr get_key_ip65
  cmp #KEYCODE_ABORT
  bne @not_abort
  jmp main_menu
@not_abort:  
  cmp #KEYCODE_F1
  bne @not_ip
  ldax #new
  jsr print
  ldax #ip_address_msg
  jsr print
  jsr print_cr
  ldax #filter_ip
  ldy #20
  jsr get_filtered_input
  bcs @no_ip_address_entered
  jsr parse_dotted_quad  
  bcc @no_ip_resolve_error  
  jmp @change_config
@no_ip_resolve_error:  
  ldax #dotted_quad_value
  stax copy_src
  ldax #cfg_ip
  stax copy_dest
  ldax #4
  jsr copymem
@no_ip_address_entered:  
  jmp @change_config
  
@not_ip:
  cmp #KEYCODE_F2
  bne @not_netmask
  ldax #new
  jsr print
  ldax #netmask_msg
  jsr print
  jsr print_cr
  ldax #filter_ip
  ldy #20
  jsr get_filtered_input
  bcs @no_netmask_entered
  jsr parse_dotted_quad  
  bcc @no_netmask_resolve_error  
  jmp @change_config
@no_netmask_resolve_error:  
  ldax #dotted_quad_value
  stax copy_src
  ldax #cfg_netmask
  stax copy_dest
  ldax #4
  jsr copymem
@no_netmask_entered:  
  jmp @change_config
  
@not_netmask:
  cmp #KEYCODE_F3
  bne @not_gateway
  ldax #new
  jsr print
  ldax #gateway_msg
  jsr print
  jsr print_cr
  ldax #filter_ip
  ldy #20
  jsr get_filtered_input
  bcs @no_gateway_entered
  jsr parse_dotted_quad  
  bcc @no_gateway_resolve_error  
  jmp @change_config
@no_gateway_resolve_error:  
  ldax #dotted_quad_value
  stax copy_src
  ldax #cfg_gateway
  stax copy_dest
  ldax #4
  jsr copymem
  jsr arp_calculate_gateway_mask                ;we have modified our netmask, so we need to recalculate gw_test
@no_gateway_entered:  
  jmp @change_config
  
  
@not_gateway:
  cmp #KEYCODE_F4
  bne @not_dns_server
  ldax #new
  jsr print
  ldax #dns_server_msg
  jsr print
  jsr print_cr
  ldax #filter_ip
  ldy #20
  jsr get_filtered_input
  bcs @no_dns_server_entered
  jsr parse_dotted_quad  
  bcc @no_dns_resolve_error  
  jmp @change_config
@no_dns_resolve_error:  
  ldax #dotted_quad_value
  stax copy_src
  ldax #cfg_dns
  stax copy_dest
  ldax #4
  jsr copymem
@no_dns_server_entered:  
  
  jmp @change_config
  
@not_dns_server:
  cmp #KEYCODE_F5
  bne @not_tftp_server
  ldax #new
  jsr print
  ldax #tftp_server_msg
  jsr print
  jsr print_cr
  ldax #filter_dns
  ldy #40
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
  jmp @change_config
  
@not_tftp_server:


cmp #KEYCODE_F6
  bne @not_reset
  jsr ip65_init ;this will reset everything
  jmp @change_config
@not_reset:  
cmp #KEYCODE_F7
  bne @not_main_menu
  jmp main_menu
  
@not_main_menu:
  jmp @get_key_config_menu
    

@resolve_error:
  print_failed
  jsr wait_for_keypress
  jsr @change_config
  
  
@tftp_boot:  

  
  ldax #tftp_dir_filemask
  
@get_tftp_directory_listing:  
  stax nb65_param_buffer+NB65_TFTP_FILENAME

  
  ldax #tftp_dir_buffer
  stax nb65_param_buffer+NB65_TFTP_POINTER

  ldax #getting_dir_listing_msg
	jsr print

  ldax  #nb65_param_buffer
  nb65call #NB65_TFTP_DOWNLOAD

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
  jmp main_menu
@tftp_filename_set:
  stax  copy_dest
  stax  get_value_of_axy+1
  ldy #0
  jsr get_value_of_axy ;A now == first char in string we just downloaded
  cmp #'$'
  bne @not_directory_name
  ;it's a directory name, so we need to append the file mask to end of it
  ;this will fail if the file path is more than 255 characters long
@look_for_trailing_zero:
   iny
    inc copy_dest
    bne :+
    inc copy_dest+1
: 
   jsr get_value_of_axy ;A now == next char in string we just downloaded
   bne  @look_for_trailing_zero
   
; got trailing zero
  ldax  #tftp_dir_filemask+1 ;skip the leading '$'
  stax  copy_src
  ldax  #$07
  jsr copymem   
  ldax get_value_of_axy+1
  jmp @get_tftp_directory_listing

@not_directory_name:
  ldax  get_value_of_axy+1
  jsr download
  bcc @file_downloaded_ok
@tftp_boot_failed:  
  jsr wait_for_keypress
  jmp main_menu
  
  
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

  jmp @tftp_boot_failed
  
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

  .if (BANKSWITCH_SUPPORT=$03)
  ldax #cant_boot_basic
  jsr print
  jsr wait_for_keypress
  jmp init
  
  .else

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
 .endif  
 
@not_a_basic_file:  
  ldax  nb65_param_buffer+NB65_TFTP_POINTER
exit_cart_via_ax:  
  sta call_downloaded_prg+1
  stx call_downloaded_prg+2
  jmp exit_cart
 
.if (BANKSWITCH_SUPPORT=$03)
net_apps_menu: 
  jsr cls  
  ldax  #netboot65_msg
  jsr print
  ldax  #net_apps_menu_msg
  jsr print
@get_key:  
  jsr get_key_ip65
  cmp #KEYCODE_ABORT
  bne @not_abort
  jmp main_menu
@not_abort:  
  cmp #KEYCODE_F1
  bne @not_telnet
  jsr cls
  lda #14
  jsr print_a ;switch to lower case  
  jmp telnet_main_entry
@not_telnet:
  cmp #KEYCODE_F3
  bne @not_gopher_floodgap_com
  jsr cls
  lda #14
  jsr print_a ;switch to lower case
  
  ldax #gopher_initial_location
  sta resource_pointer_lo
  stx resource_pointer_hi
  ldx #0
  jsr  select_resource_from_current_directory

  jmp exit_gopher
@not_gopher_floodgap_com:
  cmp #KEYCODE_F5
  bne @not_gopher
  jsr cls
  lda #14
  jsr print_a ;switch to lower case
  jsr prompt_for_gopher_resource ;only returns if no server was entered.
  jmp exit_gopher
  
@not_gopher:
  cmp #KEYCODE_F7
  bne @not_main
  jmp main_menu
@not_main:  
  jmp @get_key
  
.endif

  
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

.if (BANKSWITCH_SUPPORT=$03)
exit_telnet:
exit_gopher:
  lda #142
  jsr print_a ;switch to upper case
  lda #$05  ;petscii for white text
  jsr print_a
  jmp main_menu
.endif  
	.rodata

netboot65_msg: 
.byte 13,"NB65 - VERSION "
.include "nb65_version.i"
.byte 13,0
main_menu_msg:
.byte 13,"             MAIN MENU",13,13
.byte "F1: TFTP BOOT"
.if (BANKSWITCH_SUPPORT=$03)
.byte "     F3: NET APPS"
.else
.byte "     F3: BASIC"
.endif
.byte 13
.byte "F5: ARP TABLE     F7: CONFIG",13,13
.byte 0


config_menu_msg:
.byte 13,"              CONFIGURATION",13,13
.byte "F1: IP ADDRESS     F2: NETMASK",13
.byte "F3: GATEWAY        F4: DNS SERVER",13
.byte "F5: TFTP SERVER    F6: RESET TO DEFAULT",13
.byte "F7: MAIN MENU",13,13
.byte 0


.if (BANKSWITCH_SUPPORT=$03)
net_apps_menu_msg:
.byte 13,"              NET APPS",13,13
.byte "F1: TELNET    F3: GOPHER.FLOODGAP.COM",13
.byte "F5: GOPHER    F7: MAIN MENU",13,13
.byte 0

cant_boot_basic:
.byte "BASIC FILE EXECUTION NOT SUPPORTED",13,0
gopher_initial_location:
.byte "1gopher.floodgap.com",$09,"/",$09,"gopher.floodgap.com",$09,"70",$0D,$0A,0

.endif
downloading_msg:  .asciiz "DOWNLOADING "

getting_dir_listing_msg: .byte "FETCHING DIRECTORY",13,0

tftp_dir_listing_fail_msg:
	.byte "DIR LISTING FAILED",13,0

tftp_download_fail_msg:
	.byte "DOWNLOAD FAILED", 13, 0

tftp_download_ok_msg:
	.byte "DOWNLOAD OK", 13, 0
  
current:
.byte "CURRENT ",0

new:
.byte"NEW ",0
  
tftp_dir_filemask:  
  .asciiz "$/*.prg"

tftp_file:  
  .asciiz "BOOTC64.PRG"

no_files_on_server:
  .byte "NO MATCHING FILES",13,0

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