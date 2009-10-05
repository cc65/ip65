; #############
; KIPPER KART - A C64 TCP/IP stack as a 16KB cartridge
; jonno@jamtronix.com 

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

  .macro kippercall arg
    ldy arg
    jsr KPR_DISPATCH_VECTOR
  .endmacro

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif
  .include "../inc/common.i"
  .include "../inc/c64keycodes.i"
  .include "../inc/menu.i"

  KEY_NEXT_PAGE=KEYCODE_F7
  KEY_PREV_PAGE=KEYCODE_F1
  KEY_SHOW_HISTORY=KEYCODE_F2
  KEY_BACK_IN_HISTORY=KEYCODE_F3
  KEY_NEW_SERVER=KEYCODE_F5

  .include "../inc/ping.i"
  .include "../inc/sidplay.i"

  .include "../inc/disk_transfer.i"

  .import cls
  .import beep
  .import exit_to_basic
  .import timer_vbl_handler
  .import kipper_dispatcher
  .import ip65_process
  .import ip65_init
  .import get_filtered_input
  .import filter_text
  .import filter_dns
  .import filter_ip
  .import arp_calculate_gateway_mask
  .import parse_dotted_quad
  .import dotted_quad_value
  .import parse_integer
  .import print_integer
  .import get_key_ip65   
  .import cfg_ip
	.import cfg_netmask
	.import cfg_gateway
	.import cfg_dns
  .import cfg_tftp_server
  
  .import print_ascii_as_native
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
  .import press_a_key_to_continue
  
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
  .import  __SELF_MODIFIED_CODE_LOAD__
  .import  __SELF_MODIFIED_CODE_RUN__
  .import  __SELF_MODIFIED_CODE_SIZE__
    
  .import cfg_tftp_server
  kipper_param_buffer = $6000
  directory_buffer = $4020


.bss
temp_ptr: .res 2
.segment "SELF_MODIFIED_CODE"

call_downloaded_prg: 
   jsr $0000 ;overwritten when we load a file
   jmp cold_init
   
get_value_of_axy: ;some more self-modifying code
	lda $ffff,y
  rts


.segment "CARTRIDGE_HEADER"
.word cold_init  ;cold start vector
.word warm_init  ;warm start vector
.byte $C3,$C2,$CD,$38,$30 ; "CBM80"
.byte "KIPPER"         ; API signature
jmp kipper_dispatcher    ; KPR_DISPATCH_VECTOR   : entry point for KIPPER functions
jmp ip65_process          ;KPR_PERIODIC_PROCESSING_VECTOR : routine to be periodically called to check for arrival of ethernet packets
.byte $0,$0,$0             ;reserved for future use
.code

  
  
cold_init:

  ;first let the kernal do a normal startup
  sei
  jsr $fda3   ;initialize CIA I/O
  jsr $fd50   ;RAM test, set pointers
  jsr $fd15   ;set vectors for KERNAL
  jsr $ff5B   ;init. VIC
  cli         ;KERNAL init. finished

warm_init:
  ;set some funky colours

  LDA #$04  ;purple

  STA $D020 ;border
  LDA #$00  ;black 
  STA $D021 ;background
  lda #$05  ;petscii for white text
  jsr print_a

;relocate our r/w data
  ldax #__DATA_LOAD__
  stax copy_src
  ldax #__DATA_RUN__
  stax copy_dest
  ldax #__DATA_SIZE__
  jsr copymem


;relocate the self-modifying code (if necessary)
  ldax #__SELF_MODIFIED_CODE_LOAD__
  stax copy_src
  ldax #__SELF_MODIFIED_CODE_RUN__
  stax copy_dest
  ldax #__SELF_MODIFIED_CODE_SIZE__
  jsr copymem

  ldax #netboot65_msg
  jsr print
  ldax #init_msg+1
	jsr print
  
  kippercall #KPR_INITIALIZE
  bcc init_ok
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

init_ok:

;look for an 'autoexec' file
  jsr print_cr
  ldax #loading_msg
  jsr print
  ldax #autoexec_filename  
  stax io_filename
  jsr print
  jsr print_cr
  ldax #$0000
  jsr io_read_file
  bcs main_menu
@file_read_ok:
  ldax #load_ok_msg
  jsr print
  ldax io_load_address
  jmp boot_into_file  

main_menu:
  jsr print_main_menu
  jsr print_ip_config
  jsr print_cr
  
@get_key:
  jsr get_key_ip65
  cmp #KEYCODE_F1
  bne @not_f1
  jmp @tftp_boot
 @not_f1:  
  cmp #KEYCODE_F2
  bne @not_f2
  jmp disk_boot
 @not_f2:  

  cmp #KEYCODE_F3      
  bne @not_f3  
  jsr upload_d64
  jmp main_menu
@not_f3:  
  cmp #KEYCODE_F4
  bne @not_f4
  jsr d64_download
  jmp main_menu
@not_f4:  

  cmp #KEYCODE_F5 
  bne @not_f5
  jmp netplay_sid
@not_f5:

  cmp #KEYCODE_F6
  bne @not_f6
  jsr cls
  lda #14
  jsr print_a ;switch to lower case
  ldax #ping_header
  jsr print
  jsr ping_loop
  jmp exit_ping

@not_f6:

  cmp #KEYCODE_F7
  beq @change_config
  
  jmp @get_key

@exit_to_prog:
  ldax #$fe66 ;do a wam start
  jmp call_downloaded_prg


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
  stax kipper_param_buffer 
  jsr print_cr  
  ldax #resolving
  jsr print
  ldax #kipper_param_buffer
  kippercall #KPR_DNS_RESOLVE  
  bcs @resolve_error  
  ldax #kipper_param_buffer
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
  jsr get_tftp_directory_listing
  bcs return_to_main
  
@boot_filename_set:
  ;AX now points to filename
  jsr download
  bcc file_downloaded_ok
tftp_boot_failed:  
  jsr wait_for_keypress
return_to_main:  
  jmp error_handler

file_downloaded_ok:    
ldax kipper_param_buffer+KPR_TFTP_POINTER
  
boot_into_file:
  stax  kipper_param_buffer ;use the param buffer as a temp holding place for the load address
  ;get ready to bank out
  kippercall #KPR_DEACTIVATE   

  jsr $ffe7 ; make sure all files have been closed.
  
  ;check whether the file we just downloaded was a BASIC prg
  lda kipper_param_buffer
  cmp #01
  bne @not_a_basic_file
  
  lda kipper_param_buffer+1
  cmp #$08
  bne @not_a_basic_file

  lda $805
  cmp #$9e  ;opcode for 'SYS'
  bne @not_a_basic_stub
 
  ldax  #$806  ;should point to ascii string containing address that was to be SYSed
  jsr parse_integer 
  jmp exit_cart_via_ax ;good luck! 
@not_a_basic_stub:  
  ldax #cant_boot_basic
  jsr print
  jsr wait_for_keypress
  jmp warm_init
   
@not_a_basic_file:
  ldax  kipper_param_buffer
exit_cart_via_ax:  
  sta call_downloaded_prg+1
  stx call_downloaded_prg+2
  jmp call_downloaded_prg

get_tftp_directory_listing:  
  stax  temp_ptr
@get_listing:  
  stax kipper_param_buffer+KPR_TFTP_FILENAME
  
  ldax #directory_buffer
  stax kipper_param_buffer+KPR_TFTP_POINTER

  ldax #getting_dir_listing_msg
	jsr print

  ldax  #kipper_param_buffer
  kippercall #KPR_TFTP_DOWNLOAD

	bcs @dir_failed

  lda directory_buffer ;get the first byte that was downloaded
  bne :+
  jmp @no_files_on_server
:  

  ;switch to lower case charset
  lda #23
  sta $d018


  ldax  #directory_buffer
  
  jsr select_option_from_menu  
  bcc @tftp_filename_set
  rts
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
  ldax  temp_ptr
  clc
  adc #1   ;skip the leading '$'
  bcc :+
  inx
:  
  stax  copy_src
  ldax  #$07
  jsr copymem   
  ldax get_value_of_axy+1
  jmp @get_listing

@not_directory_name:
  ldax  get_value_of_axy+1
  clc
  rts
  
@dir_failed:  
  ldax  #dir_listing_fail_msg
  jsr print
  sec
  rts
    
@no_files_on_server:
  ldax #no_files
	jsr print
  sec
  rts
   
disk_boot:
  .import io_read_catalogue
  .import io_device_no
  .import io_filename
  .import io_read_file
  .import io_load_address
  lda #00 ;use default drive
  sta io_device_no

  ldax #directory_buffer
  jsr io_read_catalogue
  
  lda directory_buffer ;get the first byte that was downloaded
  bne :+
  jmp @no_files_on_disk
:  

  ;switch to lower case charset


  ldax  #directory_buffer
  
  jsr select_option_from_menu  
  bcc @disk_filename_set
  jmp main_menu
  
@dir_failed:  
  ldax  #dir_listing_fail_msg
@print_error:  
  jsr print
  jsr print_errorcode
  jsr print_cr
  jmp @wait_keypress_then_return_to_main
  
@no_files_on_disk:
  ldax #no_files
	jsr print
@wait_keypress_then_return_to_main:  
  jsr wait_for_keypress
  jmp main_menu

@disk_filename_set:
  stax io_filename
  ldax #loading_msg
	jsr print
  ldax io_filename
  jsr print  
  jsr print_cr
  ldax #$0000
  jsr io_read_file
  bcc @file_read_ok
  ldax #file_read_error
  jmp @print_error
@file_read_ok:
  ldax #load_ok_msg
  jsr print
  ldax io_load_address
  jmp boot_into_file
  
error_handler:  
  jsr print_errorcode
  jsr print_cr
  jsr wait_for_keypress
  jmp main_menu
  
netplay_sid:
  
  ldax #sid_filemask
  jsr get_tftp_directory_listing
  bcc @sid_filename_set
  jmp error_handler
@sid_filename_set:
  ;AX now points to filename
  stax kipper_param_buffer+KPR_TFTP_FILENAME
  ldax #$1000   ;load address 
  stax kipper_param_buffer+KPR_TFTP_POINTER
  jsr download2
  
	
  bcc :+
  jmp error_handler
:  

  jsr cls
  ldax kipper_param_buffer+KPR_TFTP_FILESIZE
  stax sidfile_length
  ldax kipper_param_buffer+KPR_TFTP_POINTER
  jsr load_sid
  jsr play_sid
  

  jmp main_menu


d64_download:
  
  ldax #d64_filemask
  jsr get_tftp_directory_listing
  bcc @d64_filename_set
  jmp main_menu
@d64_filename_set:
  ;AX now points to filename
  jsr download_d64
  jmp main_menu

  

  
bad_boot:
  jsr wait_for_keypress
  jmp $fe66   ;do a wam start

download: ;AX should point at filename to download
  stax kipper_param_buffer+KPR_TFTP_FILENAME
  ldax #$0000   ;load address will be first 2 bytes of file we download (LO/HI order)
  stax kipper_param_buffer+KPR_TFTP_POINTER

download2:
  ldax #downloading_msg
	jsr print
  ldax kipper_param_buffer+KPR_TFTP_FILENAME
  jsr print_ascii_as_native
  jsr print_cr
  
  ldax #kipper_param_buffer
  kippercall #KPR_TFTP_DOWNLOAD
  
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
  jsr KPR_PERIODIC_PROCESSING_VECTOR
  jsr $ffe4
  beq @loop
  rts


cfg_get_configuration_ptr:
  ldax #kipper_param_buffer  
  kippercall #KPR_GET_IP_CONFIG
  rts

exit_ping:
  lda #142
  jsr print_a ;switch to upper case
  lda #$05  ;petscii for white text
  jsr print_a
  jmp main_menu
.rodata

netboot65_msg: 
.byte 13,"KIPPERKART V"
.include "../inc/version.i"
.byte 13,0
main_menu_msg:
.byte 13,"MAIN MENU",13,13
.byte "F1: TFTP BOOT   F2: DISK BOOT",13
.byte "F3: UPLOAD D64  F4: DOWNLOAD D64",13
.byte "F5: SID NETPLAY F6: PING",13
.byte "F7: CONFIG",13,13

.byte 0

config_menu_msg:
.byte 13,"CONFIGURATION",13,13
.byte "F1: IP ADDRESS  F2: NETMASK",13
.byte "F3: GATEWAY     F4: DNS SERVER",13
.byte "F5: TFTP SERVER F6: RESET TO DEFAULT",13
.byte "F7: MAIN MENU",13,13
.byte 0

cant_boot_basic:
.byte "BASIC FILE EXECUTION NOT SUPPORTED",13,0

ping_header: .byte "ping",13,0

file_read_error: .asciiz "ERROR READING FILE"
autoexec_filename: .byte "AUTOEXEC.PRG",0

downloading_msg:  .byte "DOWN"
loading_msg:  .asciiz "LOADING "

uploading_msg:  .byte "UPLOADING ",0

getting_dir_listing_msg: .byte "FETCHING DIRECTORY",13,0

dir_listing_fail_msg:
	.byte "DIR FAILED",13,0

tftp_download_fail_msg:
	.byte "DOWNLOAD FAILED", 13, 0

tftp_download_ok_msg:
	.byte "DOWN"
load_ok_msg:
	.byte "LOAD OK", 13, 0

current:
.byte "CURRENT ",0

new:
.byte"NEW ",0
  
tftp_dir_filemask:  
  .asciiz "$/*.prg"

d64_filemask:  
  .asciiz "$/*.d64"

sid_filemask:
  .asciiz "$/*.sid"

no_files:
  .byte "NO FILES",13,0

resolving:
  .byte "RESOLVING ",0

remote_host: .byte "HOSTNAME (LEAVE BLANK TO QUIT)",13,": ",0
