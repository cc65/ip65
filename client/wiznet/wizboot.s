; #############
;
; jonno@jamtronix.com - May 2011
;

  
  .include "../inc/common.i"
  .include "commonprint.i"

  .import ip65_init
  .import dhcp_init
  .import tftp_ip
  .importzp tftp_filename
  .import tftp_load_address
  .import tftp_download
  .import tftp_callback_vector

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
  .import dns_ip
  .import dns_set_hostname
  .import dns_resolve
  
  
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
    
  SCNKEY=$FF9F ;Query keyboard - put matrix code into  $00CB & status of shift keys $028D 
  
  .bss
tmp_load_address: .res 2
shift_pressed_on_bootup	: .res 1

  .data
exit_cart:

call_downloaded_prg: 
   jsr $0000 ;overwritten when we load a file
   jmp warm_init
   

.segment "CARTRIDGE_HEADER"
.word cold_init  ;cold start vector
.word warm_init  ;warm start vector
.byte $C3,$C2,$CD,$38,$30 ; "CBM80"
.byte $0,$0,$0             ;reserved for future use
.byte $0,$0,$0             ;reserved for future use
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

  jsr SCNKEY ;Query keyboard - put matrix code into  $00CB & status of shift keys $028D 
  lda	$028D 
  and 	#$02
  beq	@commodore_key_not_pressed
  jmp	$e394
@commodore_key_not_pressed:

  lda	$028D 
  and 	#$01
  sta	shift_pressed_on_bootup	
  
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
  ldax #__SELF_MODIFIED_CODE_LOAD__
  stax copy_src
  ldax #__SELF_MODIFIED_CODE_RUN__
  stax copy_dest
  ldax #__SELF_MODIFIED_CODE_SIZE__
  jsr copymem


  ldax #wizboot_msg
  jsr print
   
  ;monkey patch the TFTP callback handler
  ldax tftp_callback_vector+1
  stax new_tftp_callback_vector+1
  ldax #new_tftp_callback_vector
  stax tftp_callback_vector+1
  
  jsr ip65_init
  
  bcs init_failed
  jsr dhcp_init
  bcc init_ok
init_failed:  

  jsr print_errorcode
  jsr print_ip_config
flash_forever:  
  inc $d020
  jmp flash_forever
init_ok:

  lda shift_pressed_on_bootup
  bne @skip_resolving_tftp_hostname

 ldax #resolving_tftp_hostname
  jsr print
  jsr print_cr
  ldax #tftp_hostname
  jsr dns_set_hostname 
  bcs init_failed
  jsr dns_resolve
  bcs init_failed
  
  ldx #$03
@copy_tftp_ip_loop:
  lda dns_ip,x
  sta cfg_tftp_server,x
  dex
  bpl @copy_tftp_ip_loop

@skip_resolving_tftp_hostname:

  ldx #$03
:
  lda cfg_tftp_server,x
  sta tftp_ip,x
  dex
  bpl :-
  
  jsr print_cr
  jsr print_ip_config

tftp_boot:  
  
  ldax #tftp_file
  stax tftp_filename
   
  
  ldax #$0000   ;load address will be first 2 bytes of file we download (LO/HI order)
  stax tftp_load_address

	ldax #downloading_msg
	jsr print
 	ldax tftp_filename
  	jsr print  
  	jsr print_cr
    jsr tftp_download
  
  	bcc file_downloaded_ok
  


	ldax #tftp_download_fail_msg  
	jsr print
  	jsr print_errorcode
  	jsr wait_for_keypress
return_to_main:  
  	jmp tftp_boot

file_downloaded_ok:    

	ldax #tftp_download_ok_msg
	jsr print
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

wizboot_msg: 
.byte 147,14,13,"wiznet cart - v"
.include "../inc/version.i"

.byte 13
.byte 13," hold c= for basic / shift for lan boot",13,13
.byte 0
downloading_msg:  .byte 13,"downloading ",0

tftp_download_fail_msg:
	.byte "download failed", 13, 0

tftp_download_ok_msg:
	.byte 13,"download ok", 13, 0

tftp_file:  
  .asciiz "bootc64.prg"

resolving_tftp_hostname:
	.byte "resolving "
tftp_hostname:
  .asciiz "jamtronix.com"
  
 .data
 	new_tftp_callback_vector:
 		jsr $ffff
		lda #'.'
		jmp	print_a
		
;we need a 'dummy' segment here - some drivers use this segment (e.g. wiznet), some don't (e.g. rr-net)
;if we don't declare this, we get an 'undefined segment' error when linking to a driver that doesn't use it.
.segment "SELF_MODIFIED_CODE"  

;-- LICENSE FOR wizboot.s --
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
; The Original Code is wizboot.
; 
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2011
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
