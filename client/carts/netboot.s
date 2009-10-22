; #############
; 
; This will boot a C64 with an RR-NET compatible cs8900a  from the network
; requires
; 1) a DHCP server, and
; 2) a TFTP server that responds to requests on the broadcast address (255.255.255.255) and that will serve a file called 'BOOTC64.PRG'.
;
; jonno@jamtronix.com - January 2009
;

  
  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/c64keycodes.i"
  .include "../inc/menu.i"

  .import ip65_init
  .import dhcp_init
  .import tftp_ip
  .importzp tftp_filename
  .import tftp_load_address
  .import tftp_download

  .import cls
  .import beep
  .import exit_to_basic
  .import timer_vbl_handler
  .import get_key_ip65   
  .import cfg_ip
	.import cfg_netmask
	.import cfg_gateway
	.import cfg_dns
  .import cfg_tftp_server
  .import cfg_get_configuration_ptr

  
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
    
  
  directory_buffer = $6020
  .bss
tmp_load_address: .res 2

  .data
exit_cart:

  lda #$02    
  sta $de00   ;turns off RR cartridge by modifying GROUND and EXROM
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
.code

  
  
init:
  
  ;first let the kernal do a normal startup
  sei
  jsr $fda3   ;initialize CIA I/O
  jsr $fd50   ;RAM test, set pointers
  jsr $fd15   ;set vectors for KERNAL
  jsr $ff5B   ;init. VIC
  cli         ;KERNAL init. finished
  
 
;we need to set up BASIC as well  
  jsr $e453   ;set BASIC vectors
  jsr $e3bf   ;initialize zero page
  
  
  ;set some funky colours
  LDA #$05  ;green  
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



  ldax #netboot_msg
  jsr print
  ldax #init_msg+1
	jsr print

  
  jsr ip65_init
  bcs @init_failed
  jsr dhcp_init
  bcc init_ok
  jsr ip65_init   ;if DHCP failed, then reinit the IP stack (which will reset IP address etc that DHCP messed with to cartridge default values)
  bcc init_ok
@init_failed:  
  print_failed
  jsr print_errorcode
  jsr wait_for_keypress  
  jmp exit_to_basic


init_ok:
    ldx #$03
:
  lda cfg_tftp_server,x
  sta tftp_ip,x
  dex
  bpl :-
  
  jsr print_cr
  jsr print_ip_config
tftp_boot:  
  
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
  jmp tftp_boot

file_downloaded_ok:    
ldax tftp_load_address
  
boot_into_file:
  stax  tmp_load_address ;use the param buffer as a temp holding place for the load address
  ;get ready to bank out

  jsr $ffe7 ; make sure all files have been closed.
  
  ;check whether the file we just downloaded was a BASIC prg
  lda tmp_load_address
  cmp #01
  bne @not_a_basic_file
  
  lda tmp_load_address+1
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
  ldax  tmp_load_address
exit_cart_via_ax:  
  sta call_downloaded_prg+1
  stx call_downloaded_prg+2
  jmp exit_cart

get_tftp_directory_listing:  
  stax tftp_filename
  
  ldax #directory_buffer
  stax tftp_load_address

  ldax #getting_dir_listing_msg
	jsr print

  jsr tftp_download

	bcs @dir_failed

  lda directory_buffer ;get the first byte that was downloaded
  bne :+
  jmp @no_files_on_server
:  

  ;switch to lower case charset
  lda #23
  sta $d018

@loop_till_filename_entered:
  ldax  #directory_buffer
  ldy #1 ;filenames will be ASCII
  jsr select_option_from_menu  
  bcs @loop_till_filename_entered
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
  jmp get_tftp_directory_listing

@not_directory_name:
  ldax  get_value_of_axy+1
  clc
  rts
    
  
@dir_failed:  
  ldax  #dir_listing_fail_msg
  jsr print
  jsr print_errorcode
  jsr print_cr
  
  ldax #tftp_file
  jmp @tftp_filename_set
  
@no_files_on_server:
  ldax #no_files
	jsr print

  jmp tftp_boot_failed
  
 
  
bad_boot:
  jsr wait_for_keypress
  jmp $fe66   ;do a wam start

download: ;AX should point at filename to download
  stax tftp_filename

  ldax #$0000   ;load address will be first 2 bytes of file we download (LO/HI order)
  stax tftp_load_address

  ldax #downloading_msg
	jsr print
  ldax tftp_filename
  jsr print  
  jsr print_cr
  
  jsr tftp_download
  
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
  jsr $ffe4
  beq @loop
  rts


.rodata

netboot_msg: 
.byte 13,"NETBOOT - V"
.include "../inc/version.i"
.byte 13,0
downloading_msg:  .byte "DOWN"
loading_msg:  .asciiz "LOADING "

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

tftp_file:  
  .asciiz "BOOTC64.PRG"

no_files:
  .byte "NO FILES",13,0

;-- LICENSE FOR netboot.s --
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
