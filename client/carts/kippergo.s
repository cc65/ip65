; #############
; KIPPER GO - Telnet/Gopher client for C64
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
  
  .include "../inc/gopher.i"
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

.bss
;temp_ax: .res 2


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
  
  ldax #gopher_initial_location
  sta resource_pointer_lo
  stx resource_pointer_hi
  ldx #0
  jsr  select_resource_from_current_directory
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

telnet_menu:
  rts

exit_telnet:
exit_gopher:
  jsr setup_screen
  jmp main_menu
.rodata

menu_header_msg: 
.byte $13,10,"KipperGo V"
.include "../inc/version.i"
.byte 10,0
main_menu_msg:
.byte 10,"Main Menu",10,10
.byte "F1: Telnet      F3: Gopher ",10
.byte "F5: Gopher (floodgap.com)",10
.byte "F7: Config      F8: Credits",10,10

.byte 0



gopher_initial_location:
.byte "1gopher.floodgap.com",$09,"/",$09,"gopher.floodgap.com",$09,"70",$0D,$0A,0

gopher_header: .byte "gopher",10,0
telnet_header: .byte "telnet",10,0

current:
.byte "current ",0

new:
.byte"new ",0
  
resolving:
  .byte "resolving ",0


credits: 
.byte 10,"License: Mozilla Public License v1.1",10,"http://www.mozilla.org/MPL/"
.byte 10
.byte 10,"Contributors:",10
.byte 10,"Jonno Downes"
.byte 10,"Glenn Holmer"
.byte 10,"Per Olofsson"
.byte 10,"Lars Stollenwerk"
.byte 10,10
.byte 0

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
