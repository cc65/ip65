; #############
; KIPPER TERM - Telnet (only) client for C64
; jonno@jamtronix.com 


  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/c64keycodes.i"
  .include "../inc/menu.i"
  .include "../inc/config_menu.i"

  KEY_NEXT_PAGE=KEYCODE_F7
  KEY_PREV_PAGE=KEYCODE_F1
  KEY_SHOW_HISTORY=KEYCODE_F2
  KEY_BACK_IN_HISTORY=KEYCODE_F3
  KEY_NEW_SERVER=KEYCODE_F5
  
  XMODEM_IN_TELNET = 1

  .import xmodem_iac_escape
  
  .include "../inc/telnet.i"
  
  .import cls
  .import beep
  .import exit_to_basic
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

 .import dns_ip
  .import dns_resolve
  .import dns_set_hostname
 
  .import get_key_ip65
  .import cfg_mac
  .import dhcp_init
  
  .import cfg_ip
	.import cfg_netmask
	.import cfg_gateway
	.import cfg_dns
  .import cfg_tftp_server

  .import xmodem_receive

  .export telnet_menu
  
  .import print_a
  .import print_cr
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
  directory_buffer = $6000


.segment "CARTRIDGE_HEADER"
.word cold_init  ;cold start vector
.word warm_init  ;warm start vector
.byte $C3,$C2,$CD,$38,$30 ; "CBM80"
.byte "KIPTRM"
.byte $0,$0,$0             ;reserved for future use
.byte $0,$0,$0             ;reserved for future use
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

  lda #0    
  sta $dc08 ;set deciseconds - starts TOD going 

  jsr setup_screen
  
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
  
  jsr ip65_init
  bcs init_failed
  jsr dhcp_init
  bcc init_ok
  jsr ip65_init   ;if DHCP failed, then reinit the IP stack (which will reset IP address etc that DHCP messed with to cartridge default values)
  bcc init_ok
init_failed:  
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

main_menu:
  jsr print_main_menu
  jsr print_ip_config
  jsr print_default_drive
  jsr print_cr
  
@get_key:
  jsr get_key_ip65
  cmp #KEYCODE_F1
  bne @not_f1
  jsr cls
  ldax #telnet_header
  jsr print_ascii_as_native
  jmp telnet_main_entry

 @not_f1:  

  cmp #KEYCODE_F7
  beq @change_config
  cmp #KEYCODE_F8
  bne @not_f8

  jsr cls  
  ldax  #menu_header_msg
  jsr print_ascii_as_native
  ldax  #credits
  jsr print_ascii_as_native
  ldax #press_a_key_to_continue
  jsr print_ascii_as_native
  jsr get_key_ip65
  jmp main_menu
@not_f8:
  
  jmp @get_key

@change_config:
  jsr configuration_menu
  jmp main_menu
    

wait_for_keypress:
  ldax  #press_a_key_to_continue
  jsr print_ascii_as_native
@loop:  
  jsr $ffe4
  beq @loop
  rts

get_key:
  jmp get_key_ip65

cfg_get_configuration_ptr:
  ldax  #cfg_mac
  rts


setup_screen:
  ;make sure normal font
  lda #$15
  sta $d018

  LDA #$07  ;yellow

  STA $D020 ;border
  LDA #$00  ;black 
  STA $D021 ;background
  lda #$05  ;petscii for white text
  jsr print_a

  lda #14
  jmp print_a ;switch to lower case 

save_screen_settings:
  ;save current settings
  lda $d018
  sta temp_font
  lda $d020
  sta temp_border
  lda $d021
  sta temp_text_back
  lda $0286
  sta temp_text_fore

  ldx #$27
@save_page_zero_vars_loop:
  lda $cf,x
  sta temp_page_zero_vars,x
  dex
  bne @save_page_zero_vars_loop
  
  ldax #$400
  stax  copy_src
  ldax #temp_screen_chars
  stax  copy_dest
  ldax #$400
  jsr copymem
  
  ldax #$d800
  stax  copy_src
  ldax #temp_colour_ram
  stax  copy_dest
  ldax #$400
  jmp copymem
  
restore_screen_settings:
  lda temp_font
  sta $d018
  
  
  lda temp_border
  sta $d020
  lda temp_text_back
  sta $d021
  lda temp_text_fore
  sta $0286
 
  ldx #$27
@restore_page_zero_vars_loop:
  lda temp_page_zero_vars,x
  sta $cf,x  
  dex
  bne @restore_page_zero_vars_loop

  ldax #temp_screen_chars
  stax  copy_src
  ldax #$400
  stax  copy_dest
  ldax #$400
  jsr copymem
  
  ldax #temp_colour_ram
  stax  copy_src  
  ldax #$d800
  stax  copy_dest
  ldax #$400
  jmp copymem


telnet_menu:
  
  jsr save_screen_settings
  jsr setup_screen
  jsr cls 
  
  ldax #menu_header_msg
  jsr print_ascii_as_native
  ldax #telnet_menu_msg
  jsr print_ascii_as_native
  
@get_menu_option:
  jsr get_key
  cmp #KEYCODE_F1
  bne :+
  jsr xmodem_download
  jmp @exit
:
  cmp #KEYCODE_F7
  beq @exit
  jmp @get_menu_option
@exit:  
  jsr restore_screen_settings  
  rts

xmodem_download:
  ldax #opening_file
  jsr print_ascii_as_native
  jsr open_dl_file
  bcs @error
  ldax #ok_msg  
  jsr print_ascii_as_native
  jsr print_cr
  ldax #write_byte
  jsr xmodem_receive
  bcs @error  
  jsr close_file
  ldax #transfer_complete
  jsr print_ascii_as_native
  ldax #prompt_for_filename
  jsr print_ascii_as_native
@get_filename:  
  ldax #filter_dns
  ldy #40
  jsr get_filtered_input
  bcs @get_filename
  jsr rename_file  


  rts
@error:
  print_failed
  jsr print_errorcode
  jsr close_file
  jmp wait_for_keypress
  
open_dl_file:  
  lda #temp_filename_end-temp_filename_start
  ldx #<temp_filename_start
  ldy #>temp_filename_start


open_file:
  ;A,X,Y set up ready for a call to SETNAM for file #2
  jsr $FFBD     ; call SETNAM
  lda #$02      ; file number 2
.import cfg_default_drive  
  ldx cfg_default_drive
  
  ldy #$02      ; secondary address 2
  jsr $FFBA     ; call SETLFS

  jsr $FFC0     ; call OPEN
  bcs @error    ; if carry set, the file could not be opened
  rts
@error:
  sta ip65_error
  jsr close_file
  sec
  rts
  
write_byte:
  pha
  ldx #$02      ; filenumber 2 = output file
  jsr $FFC9     ; call CHKOUT 
  pla
  jsr $ffd2     ;write byte
  JSR $FFB7     ; call READST (read status byte)
  bne @error
  ldx #$00      ; filenumber 0 = console
  jsr $FFC9     ; call CHKOUT 
  rts
@error:  
  lda #KPR_ERROR_FILE_ACCESS_FAILURE
  sta ip65_error
  jsr close_file
  sec
  rts
  
  
close_file:

  lda #$02      ; filenumber 2
  jsr $FFC3     ; call CLOSE  
  rts


rename_file:
;AX points at new filename
  stax  copy_src
  ldx #0
  ldy #0
  ;first the "RENAME0:"

: 
  lda rename_cmd,y
  sta command_buffer,x
  inx
  iny
  cmp #':'
  bne :-
  
  ;now the new filename
  ldy #0
:  
  lda (copy_src),y
  beq @end_of_new_filename
  sta command_buffer,x
  inx
  iny
  bne :-
@end_of_new_filename:
  
  ;now the "="
  lda #'='
  sta command_buffer,x
  inx

  ;now the old filename
  ldy #0
:  
  lda temp_filename,y
  cmp #','
  beq @end_of_old_filename
  sta command_buffer,x
  inx
  iny
  bne :-
@end_of_old_filename:  
  txa ;filename length
  ldx #<command_buffer
  ldy #>command_buffer
  
  jsr $FFBD     ; call SETNAM
  lda #$0F      ; filenumber 15
  ldx cfg_default_drive
  ldy #$0F      ; secondary address 15
  jsr $FFBA     ; call SETLFS
  jsr $FFC0     ; call OPEN
  lda #$0F      ; filenumber 15
  jsr $FFC3     ; call CLOSE  
  rts
  
rename_cmd:
  .byte "RENAME0:"
;  FOO.BAR=0:XMODEM.TMP"

exit_telnet:
exit_gopher:
  jsr setup_screen
  jmp main_menu
.rodata

menu_header_msg: 
.byte $13,10,"KipperTerm V"
.include "../inc/version.i"
.byte 10,0
main_menu_msg:
.byte 10,"Main Menu",10,10
.byte "F1: Telnet ",10
.byte "F7: Config      F8: Credits",10,10

.byte 0


telnet_menu_msg:
.byte 10,10,10
.byte "F1: D/L File (XMODEM)",10
.byte "F7: Return",10,10
.byte 0

telnet_header: .byte "telnet",10,0

opening_file:
.byte 10,"opening file",10,0
transfer_complete:
.byte "transfer complete.",10,0
prompt_for_filename: .byte "save file as?",10,0
current:
.byte "current ",0

new:
.byte"new ",0
  
resolving:
  .byte "resolving ",0

temp_filename_start:  .byte "@"
temp_filename:
.byte "0:XMODEM.TMP,P,W"  ; @0: means 'overwrite if existing', ',P,W' is required to make this an output file
temp_filename_end:
.byte 0

credits: 
.byte 10,"License: Mozilla Public License v1.1",10,"http://www.mozilla.org/MPL/"
.byte 10
.byte 10,"Contributors:",10
.byte 10,"Jonno Downes"
.byte 10,"Glenn Holmmer"
.byte 10,"Per Olofsson"
.byte 10,"Lars Stollenwerk"
.byte 10,10
.byte 0

.segment "APP_SCRATCH"

temp_font: .res 1 
temp_border: .res 1
temp_text_back: .res 1
temp_text_fore: .res 1
temp_page_zero_vars: .res $28
temp_screen_chars: .res $400
temp_colour_ram: .res $400
command_buffer: .res $80
;-- LICENSE FOR kipperterm.s --
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
; The Original Code is KipperTerm.
; 
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
