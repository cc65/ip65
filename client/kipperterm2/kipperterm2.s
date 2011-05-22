; #############
; KIPPERTERM 2 - Telnet/Gopher client for C64
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
   GOPHER_BUFFER_SIZE = 2000
  .include "../inc/gopher.i"
  .include "../inc/telnet.i"
 

  .import xmodem_iac_escape
  .import io_error_buffer
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
  

  .import xmodem_receive
  .import xmodem_send

  .import get_key_ip65
  .import cfg_mac
  .import dhcp_init
  
  .import cfg_ip
	.import cfg_netmask
	.import cfg_gateway
	.import cfg_dns
  .import cfg_tftp_server

  .import xmodem_receive

  .import tcp_send
  .import tcp_send_data_len
  
  .import io_read_catalogue
  .import io_device_no
  .import io_read_file
  .import io_filename
  .import io_filesize
  .export telnet_menu
  
  .import print_a
  .import print_cr
  .import copymem
	.importzp copy_src
	.importzp copy_dest
  .import get_filtered_input
    
  .import cfg_tftp_server

.bss
;temp_ax: .res 2


	.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

	.word basicstub		; load address

basicstub:
	.word @nextline
	.word 2003
	.byte $9e
  .byte <(((init / 10000) .mod 10) + $30)
	.byte <(((init / 1000) .mod 10) + $30)
	.byte <(((init / 100 ) .mod 10) + $30)
	.byte <(((init / 10  ) .mod 10) + $30)
	.byte <(((init       ) .mod 10) + $30)
	.byte 0
@nextline:
	.word 0

.code

  
    
init:
  lda #$36
  sta $01 ;turn off BASIC
  jsr setup_screen
  
  ldax #menu_header_msg
  jsr print_ascii_as_native
  ldax #init_msg+1
	jsr print_ascii_as_native
  ldax #eth_driver_name
	jsr print_ascii_as_native
  lda #' '
   jsr	print_a
  lda eth_driver_io_base+1
  jsr	print_hex
  lda eth_driver_io_base
  jsr	print_hex
  lda #' '  
  jsr	print_a
  jsr ip65_init
  bcs init_failed
  jsr dhcp_init
  bcc init_ok
  jsr ip65_init   ;if DHCP failed, then reinit the IP stack (which will reset IP address etc that DHCP messed with to  default values)
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

  lda $ba
  sta cfg_default_drive

main_menu:
  jsr print_main_menu
  jsr print_ip_config
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
  cmp #KEYCODE_F3
  bne @not_f3
  jsr cls
  ldax #gopher_header
  jsr print_ascii_as_native
  jsr prompt_for_gopher_resource ;only returns if no server was entered.
  jmp exit_gopher
 @not_f3:  

  cmp #KEYCODE_F5
  bne @not_f5
  jsr cls
  
  clc
  jsr set_io_device_no
  ldax #address_book_filename
  stax io_filename
  ldax #scratch_buffer
  jsr io_read_file
  bcc @no_error_reading_address_book
  ldax #address_book_fail_msg 
  jsr print_ascii_as_native
  jsr print_errorcode
  ldax #address_book_filename
  jsr print_ascii_as_native
  jsr print_cr
  ldax #drive_text
  jsr print
  lda $ba
  ldx #0
  jsr print_integer
  jsr print_cr
  
  ldax #io_error_buffer
  jsr print

  jsr wait_for_keypress  
  jmp main_menu
  
@no_error_reading_address_book:


  lda #'1'
  sta displayed_resource_type
  
;put a nul byte at end of file
  ldax #scratch_buffer
  stax pptr
  clc
  lda io_filesize
  adc #<scratch_buffer
  sta pptr  
  lda io_filesize+1
  adc #>scratch_buffer
  sta pptr+1
  lda #0
  tay
  sta (pptr),y  
  inc $d020
  jsr display_resource_in_buffer
  
  jmp exit_gopher  
@not_f5:  

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
  jsr cls
  ;make sure normal font
  lda #$15
  sta $d018

  LDA #$06  ;blue

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
 
@show_menu:
   
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
  cmp #KEYCODE_F3
  bne :+
  jsr xmodem_upload
  jmp @exit
:
  cmp #KEYCODE_F5
  bne :+
@get_ascii_value:
  ldax #enter_ascii
  jsr print_ascii_as_native
  ldy #3 ;max chars
  ldax #filter_number
  jsr get_filtered_input  
  bcs @show_menu  
  ;AX now points a string containing 0..999
  .import parse_integer
  jsr parse_integer
  cpx #0
  bne @get_ascii_value
  sta ascii_packet
  lda #1
  stax tcp_send_data_len 
  jsr restore_screen_settings  ;since we won't return from tcp_send
  ldax #ascii_packet
  jmp tcp_send
  
  
:
  cmp #KEYCODE_F7
  beq @exit
  jmp @get_menu_option
@exit:  
  jsr restore_screen_settings  
  rts

set_io_device_no:
  lda cfg_default_drive
  sec
  sbc #7
  sta io_device_no
  rts
xmodem_upload:
  jsr set_io_device_no  
  lda #0
  sta eof

  ldax #directory_buffer
  jsr io_read_catalogue
  bcs @dir_failed
  lda directory_buffer ;get the first byte that was downloaded
  bne :+
  jmp @no_files_on_disk
:  

  ldax  #directory_buffer
  ldy #0 ;filenames will NOT be ASCII
  jsr select_option_from_menu  
  bcc @disk_filename_set
  rts
  
@dir_failed:  
  ldax  #dir_listing_fail_msg
@print_error:  
  jsr print_ascii_as_native
  jsr print_errorcode
  jsr print_cr
  jmp wait_for_keypress
  
@no_files_on_disk:
  ldax #no_files
	jsr print_ascii_as_native
@wait_keypress_then_return_to_main:  
  jmp wait_for_keypress
  

@disk_filename_set:

;open file needs XY=pointer to name, A = length of name  
  stax copy_src
  ldy #$ff
@next_byte:
  iny
  lda  (copy_src),y
  bne @next_byte
  tya
  ldx copy_src
  ldy copy_src+1
  
  jsr open_file
  ldax #read_byte
  jsr xmodem_send
  bcc @no_error
  print_failed
  jsr print_errorcode
  jmp :+
@no_error:  
  print_ok
:
  jsr close_file
  jmp wait_for_keypress


read_byte:
  lda eof
  beq @not_eof
  sec
  rts
@not_eof:  
  ldx #$02      ; filenumber 2 = output file
  jsr $FFC6     ; call CHKIN (file 2 now used as input)
  
  jsr $FFCF     ; call CHRIN (get a byte from file)
  pha
  
  jsr   $FFB7     ; call READST (read status byte)
  
  beq :+      ; either EOF or read error
  inc eof
:
  ldx #$00      ; filenumber 0 = console
  jsr $FFC6     ; call CHKIN (console now used as input)

  pla
  clc
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

  ;scratch the file first (if it exists)
  ;first copy the "S:"
  ldx #0
: 
  lda scratch_cmd,x
  sta command_buffer,x
  inx
  cmp #':'
  bne :-
  jsr copy_tmp_filename_and_execute_cmd

  lda #temp_filename_end-temp_filename
  ldx #<temp_filename
  ldy #>temp_filename


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
  ;first the "RENAME0:"

: 
  lda rename_cmd,x
  sta command_buffer,x
  inx

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

copy_tmp_filename_and_execute_cmd:
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

  
scratch_cmd:
  .byte "S:"
  
rename_cmd:
  .byte "RENAME:"

exit_telnet:
exit_gopher:
  jsr setup_screen
  jmp main_menu
.rodata

menu_header_msg: 
.byte $13,10,"KIPPERTERM 2"
.byte 10,0
main_menu_msg:
.byte 10,"Main Menu",10,10
.byte "F1: Telnet         F3: Gopher ",10
.byte "F5: Address Book",10
.byte "F7: Config         F8: Credits",10,10

.byte 0
telnet_menu_msg:
.byte 10,10,10
.byte "F1: D/L File (XMODEM)",10
.byte "F3: U/L File (XMODEM)",10
.byte "F5: Send ASCII char",10
.byte "F7: Return",10,10
.byte 0


opening_file:
.byte 10,"opening file",10,0
transfer_complete:
.byte "transfer complete.",10,0
prompt_for_filename: .byte "save file as?",10,0
current:
.byte "current ",0

enter_ascii:
.byte 10,"ASCII value (0..255)? ",0

byte_sent:
.byte 10,"byte sent.",0

new:
.byte"new ",0
  
resolving:
  .byte "resolving ",0

no_files:
  .byte "no files",10,0

address_book_fail_msg:
	.byte "couldn't open address book",10,0

dir_listing_fail_msg:
	.byte "directory listing failed",10,0

temp_filename:
.byte "XMODEM.TMP,P,W"  ; @ means 'overwrite if existing', ',P,W' is required to make this an output file
temp_filename_end:
.byte 0


address_book_filename: .byte "ADDRESSES.TXT",0

gopher_header: .byte "gopher",10,0
telnet_header: .byte "telnet",10,0

drive_text: .byte "drive #",0


credits: 
.byte 10,"License: Mozilla Public License v1.1",10,"http://www.mozilla.org/MPL/"
.byte 10
.byte 10,"Contributors:",10
.byte 10,"Jonno Downes"
.byte 10,"Glenn Holmer"
.byte 10,"Per Olofsson"
.byte 10,"Lars Stollenwerk"
.byte 10,10
.byte "Build "
.include "../inc/version.i"
.byte " ("
.include "timestamp.i"
.byte ")"
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
eof: .res 1
ascii_packet: .res 1

directory_buffer:  .res $400

;we need to reserve space at $2000..$27FF for the VT100 font table
.segment   "FONT_TABLE"
.res $800

;make a dummy cartdige header so our 
.segment "CARTRIDGE_HEADER"
.byte "80"
.byte "KIPTRM"
.byte $0,$0,$0             ;reserved for future use
.byte $0,$0,$0             ;reserved for future use
.byte $0,$0,$0             ;reserved for future use

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
