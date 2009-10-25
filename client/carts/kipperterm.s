; #############
; KIPPER TERM - Telnet/Gopher client for C64
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

  
  .include "../inc/gopher.i"
  .include "../inc/telnet.i"
  
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
  directory_buffer = $6020


.bss
temp_ptr: .res 2
.segment "SELF_MODIFIED_CODE"


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

main_menu:
  jsr print_main_menu
  jsr print_ip_config
  jsr print_cr
  
@get_key:
  jsr get_key_ip65
  cmp #KEYCODE_F1
  bne @not_f1
  jsr cls
  lda #14
  jsr print_a ;switch to lower case  
  ldax #telnet_header
  jsr print
  jmp telnet_main_entry

 @not_f1:  
  cmp #KEYCODE_F3
  bne @not_f3
  jsr cls
  lda #14
  jsr print_a ;switch to lower case
  ldax #gopher_header
  jsr print
  jsr prompt_for_gopher_resource ;only returns if no server was entered.
  jmp exit_gopher
 @not_f3:  

  cmp #KEYCODE_F5
  bne @not_f5
  jsr cls
  lda #14
  jsr print_a ;switch to lower case
  
  ldax #gopher_initial_location
  sta resource_pointer_lo
  stx resource_pointer_hi
  ldx #0
  jsr  select_resource_from_current_directory
  jmp exit_gopher  
@not_f5:  

  cmp #KEYCODE_F7
  beq @change_config
  
  jmp @get_key

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

exit_telnet:
exit_gopher:
  lda #142
  jsr print_a ;switch to upper case
  lda #$05  ;petscii for white text
  jsr print_a
  jmp main_menu
.rodata

netboot65_msg: 
.byte 13,"KIPPERTERM V"
.include "../inc/version.i"
.byte 13,0
main_menu_msg:
.byte 13,"MAIN MENU",13,13
.byte "F1: TELNET      F3: GOPHER ",13
.byte "F5: GOPHER (FLOODGAP.COM)",13
.byte "                F7: CONFIG",13,13

.byte 0

config_menu_msg:
.byte 13,"CONFIGURATION",13,13
.byte "F1: IP ADDRESS  F2: NETMASK",13
.byte "F3: GATEWAY     F4: DNS SERVER",13
.byte "F5: TFTP SERVER F6: RESET TO DEFAULT",13
.byte "F7: MAIN MENU",13,13
.byte 0

gopher_initial_location:
.byte "1gopher.floodgap.com",$09,"/",$09,"gopher.floodgap.com",$09,"70",$0D,$0A,0

gopher_header: .byte "gopher",13,0
telnet_header: .byte "telnet",13,0

current:
.byte "CURRENT ",0

new:
.byte"NEW ",0
  
resolving:
  .byte "RESOLVING ",0


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
; The Original Code is netboot65.
; 
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
