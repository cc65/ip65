; #############
; KIPPER KART - A C64 TCP/IP stack as a 16KB cartridge
; jonno@jamtronix.com 

  .macro print_failed
    ldax #failed_msg
    jsr print_ascii_as_native
    jsr print_cr
  .endmacro

  .macro print_ok
    ldax #ok_msg
    jsr print_ascii_as_native
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

  .include "../inc/ping.i"
  .include "../inc/sidplay.i"

  .include "../inc/disk_transfer.i"
  .include "../inc/config_menu.i"

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
  
  .import timer_read
  .import timer_timeout
  
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
  .import cfg_default_drive
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
filemask_ptr: .res 2
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

  jsr init_tod

  ;first let the kernal do a normal startup
  sei
  jsr $fda3   ;initialize CIA I/O
  jsr $fd50   ;RAM test, set pointers
  jsr $fd15   ;set vectors for KERNAL
  jsr $ff5B   ;init. VIC
  cli         ;KERNAL init. finished

  
warm_init:

  lda #14
  jsr print_a ;switch to lower case 

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
  
  ldax #menu_header_msg
  jsr print_ascii_as_native
  ldax #init_msg+1
  jsr print_ascii_as_native
  
  kippercall #KPR_INITIALIZE
  bcc init_ok
  print_failed
  jsr print_errorcode
  jsr wait_for_keypress  
  jmp exit_to_basic

print_main_menu:
 
  jsr cls  
  ldax  #menu_header_msg
  jsr print_ascii_as_native
  ldax  #main_menu_msg
  jmp print_ascii_as_native

init_ok:

;look for an 'autoexec' file
  jsr print_cr
  ldax #loading_msg
  jsr print_ascii_as_native
  lda cfg_default_drive
  sec
  sbc #7
  sta io_device_no
  ldax #autoexec_filename  
  stax io_filename
  jsr print_ascii_as_native
  jsr print_cr
  ldax #$0000
  jsr io_read_file
  bcs main_menu
@file_read_ok:
  ldax #load_ok_msg
  jsr print_ascii_as_native
  ldax io_load_address
  jmp boot_into_file  

main_menu:
  jsr print_main_menu
  jsr print_ip_config
  jsr print_default_drive
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
  ldax #ping_header
  jsr print_ascii_as_native
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
  jsr configuration_menu
  jmp main_menu
@tftp_boot:  

  ldax #tftp_dir_filemask
  stax filemask_ptr
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
  jsr print_ascii_as_native
  jsr wait_for_keypress
  jmp warm_init
   
@not_a_basic_file:
  ldax  kipper_param_buffer
exit_cart_via_ax:  
  sta call_downloaded_prg+1
  stx call_downloaded_prg+2
  jmp call_downloaded_prg

get_tftp_directory_listing:  

  stax kipper_param_buffer+KPR_TFTP_FILENAME
  stax copy_src
  ldax #last_dir_mask
  stax copy_dest
  ldax #$80
  jsr copymem

  ldax #directory_buffer
  stax kipper_param_buffer+KPR_TFTP_POINTER

  ldax #getting_dir_listing_msg
	jsr print_ascii_as_native

  ldax  #kipper_param_buffer
  kippercall #KPR_TFTP_DOWNLOAD

	bcs @dir_failed

  lda directory_buffer ;get the first byte that was downloaded
  bne :+
  jmp @no_files_on_server
:  


  ldax  #directory_buffer
  ldy #1 ;filenames will be ASCII
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
  ldax  filemask_ptr
  clc
  adc #1   ;skip the leading '$'
  bcc :+
  inx
:  
  stax  copy_src
  ldax  #$07
  jsr copymem   
  ldax get_value_of_axy+1
  jmp get_tftp_directory_listing

@not_directory_name:
  ldax  get_value_of_axy+1
  clc
  rts
  
@dir_failed:  
  ldax  #dir_listing_fail_msg
  jsr print_ascii_as_native
  sec
  rts
    
@no_files_on_server:
  ldax #no_files
	jsr print_ascii_as_native
  sec
  rts
   
disk_boot:
  .import io_read_catalogue
  .import io_device_no
  .import io_filename
  .import io_read_file
  .import io_load_address

  lda cfg_default_drive
  sec
  sbc #7
  sta io_device_no
  ldax #directory_buffer
  jsr io_read_catalogue
  
  lda directory_buffer ;get the first byte that was downloaded
  bne :+
  jmp @no_files_on_disk
:  


  ldax  #directory_buffer
  ldy #0 ;filenames will NOT be ASCII
  jsr select_option_from_menu  
  bcc @disk_filename_set
  jmp main_menu
  
@dir_failed:  
  ldax  #dir_listing_fail_msg
@print_error:  
  jsr print_ascii_as_native
  jsr print_errorcode
  jsr print_cr
  jmp @wait_keypress_then_return_to_main
  
@no_files_on_disk:
  ldax #no_files
	jsr print_ascii_as_native
@wait_keypress_then_return_to_main:  
  jsr wait_for_keypress
  jmp main_menu

@disk_filename_set:
  stax io_filename
  ldax #loading_msg
	jsr print_ascii_as_native
  ldax io_filename
  jsr print_ascii_as_native  
  jsr print_cr
  ldax #$0000
  jsr io_read_file
  bcc @file_read_ok
  ldax #file_read_error
  jmp @print_error
@file_read_ok:
  ldax #load_ok_msg
  jsr print_ascii_as_native
  ldax io_load_address
  jmp boot_into_file
  
error_handler:  
  jsr print_errorcode
  jsr print_cr
  jsr wait_for_keypress
  jmp main_menu
  
netplay_sid:
  
  ldax #sid_filemask
  stax filemask_ptr
@get_sid_dir:  
  
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
  
  jsr print_cr
;wait a little bit to allow the RUN/STOP key to be released
  jsr timer_read
  inx ;add 256 ms
  inx ;add 256 ms
:  
  jsr timer_timeout
	bcs :-
  
  jsr ip65_process
  lda #0
  sta $cb
    
  ldax #last_dir_mask  
  jsr @get_sid_dir


d64_download:
  
  ldax #d64_filemask
  stax filemask_ptr
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
	jsr print_ascii_as_native
  ldax kipper_param_buffer+KPR_TFTP_FILENAME
  jsr print_ascii_as_native
  jsr print_cr
  
  ldax #kipper_param_buffer
  kippercall #KPR_TFTP_DOWNLOAD
  
	bcc :+
  
	ldax #tftp_download_fail_msg  
	jsr print_ascii_as_native
  jsr print_errorcode
  sec
  rts
  
:
  ldax #tftp_download_ok_msg
	jsr print_ascii_as_native
  clc
  rts

wait_for_keypress:
  ldax  #press_a_key_to_continue
  jsr print_ascii_as_native
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
  lda #$05  ;petscii for white text
  jsr print_a
  jmp main_menu

  
;init the Time-Of-Day clock - cribbed from http://codebase64.org/doku.php?id=base:initialize_tod_clock_on_all_platforms
init_tod:
	sei
	lda	#0
	sta	$d011		;Turn off display to disable badlines
	sta	$dc0e		;Set TOD Clock Frequency to 60Hz
	sta	$dc0f		;Enable Set-TOD-Clock
	sta	$dc0b		;Set TOD-Clock to 0 (hours)
	sta	$dc0a		;- (minutes)
	sta	$dc09		;- (seconds)
	sta	$dc08		;- (deciseconds)

	lda	$dc08		;
@wait_raster:	
  cmp	$dc08		;Sync raster to TOD Clock Frequency
	beq	@wait_raster
	
	ldx	#0		;Prep X and Y for 16 bit
	ldy	#0		; counter operation
	lda	$dc08		;Read deciseconds
@loop1:
  inx			;2   -+
	bne	@loop2		;2/3  | Do 16 bit count up on
	iny			;2    | X(lo) and Y(hi) regs in a 
	jmp	@loop3		;3    | fixed cycle manner
@loop2:
  nop			;2    |
	nop			;2   -+
@loop3:
  cmp	$dc08		;4 - Did 1 decisecond pass?
	beq	@loop1		;3 - If not, loop-di-doop
				;Each loop = 16 cycles
				;If less than 118230 cycles passed, TOD is 
				;clocked at 60Hz. If 118230 or more cycles
				;passed, TOD is clocked at 50Hz.
				;It might be a good idea to account for a bit
				;of slack and since every loop is 16 cycles,
				;28*256 loops = 114688 cycles, which seems to be
				;acceptable. That means we need to check for
				;a Y value of 28.

	cpy	#28		;Did 114688 cycles or less go by?
	bcc	@hertz_correct		;- Then we already have correct 60Hz $dc0e value
	lda	#$80		;Otherwise, we need to set it to 50Hz
	sta	$dc0e
@hertz_correct:
	lda	#$1b		;Enable the display again
	sta	$d011
  cli
	rts		
  
.rodata

menu_header_msg: 
.byte $13,10,"KipperKart V"
.include "../inc/version.i"
.byte 10,0
main_menu_msg:
.byte 10,"Main Menu",10,10
.byte "F1: TFTP Boot   F2: Disk Boot",10
.byte "F3: Upload D64  F4: Download D64",10
.byte "F5: SID Netplay F6: Ping",10
.byte "F7: Config",10,10

.byte 0



cant_boot_basic:
.byte "BASIC file execution not supported",10,0

ping_header: .byte "ping",10,0

file_read_error: .asciiz "Error reading file"
autoexec_filename: .byte "AUTOEXEC.PRG",0

downloading_msg:  .byte "down"
loading_msg:  .asciiz "loading "

uploading_msg:  .byte "uploading ",0

getting_dir_listing_msg: .byte "fetching directory",10,0

dir_listing_fail_msg:
	.byte "directory listing failed",10,0

tftp_download_fail_msg:
	.byte "download failed", 10, 0

tftp_download_ok_msg:
	.byte "down"
load_ok_msg:
	.byte "load OK", 10, 0

current:
.byte "current ",0

new:
.byte"new ",0
  
tftp_dir_filemask:  
  .asciiz "$/*.prg"

d64_filemask:  
  .asciiz "$/*.d64"

sid_filemask:
  .asciiz "$/*.sid"

no_files:
  .byte "no files",10,0

resolving:
  .byte "resolving ",0

remote_host: .byte "hostname (return to quit)",10,": ",0

.segment "APP_SCRATCH"
last_dir_mask: .res 128

;-- LICENSE FOR kipperkart.s --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
; 
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
; 
; The Original Code is netboot65.
; 
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
