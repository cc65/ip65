;#############
; 
; This will boot an Apple 2 with uthernet in slot 3 from the network
; requires
; 1) a DHCP server, and
; 2) a TFTP server that responds to requests on the broadcast address (255.255.255.255) and that will serve a file called 'BOOTA2.BIN'.
;
; jonno@jamtronix.com - January 2009
;

  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  .include "../inc/a2keycodes.i"
  .include "../inc/menu.i"
  .import cls
  .import get_key
  .import beep
	
  .importzp tftp_filename
  .import tftp_load_address
  .import tftp_ip
  .import tftp_download
  .import tftp_clear_callbacks
  
	.import copymem
	.importzp copy_src
	.importzp copy_dest

  .import __STARTUP_LOAD__
  .import __STARTUP_SIZE__
  .import __BSS_LOAD__
  .import __DATA_LOAD__
  .import __DATA_RUN__
  .import __DATA_SIZE__
  .import __RODATA_LOAD__
  .import __RODATA_RUN__
  .import __RODATA_SIZE__
  .import __CODE_LOAD__
  .import __CODE_RUN__
  .import __CODE_SIZE__
  .import __IP65_DEFAULTS_LOAD__
  .import __IP65_DEFAULTS_RUN__
  .import __IP65_DEFAULTS_SIZE__
  

;.segment        "PAGE3"
;disable_language_card: .res 3
;bin_file_jmp: .res 3

disable_language_card = $101
bin_file_jmp = $104

; ------------------------------------------------------------------------

        .segment        "EXEHDR"

        .addr           __STARTUP_LOAD__                ; Start address
        .word           __STARTUP_SIZE__+__CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; Size

; ------------------------------------------------------------------------

  
tftp_dir_buffer = $4000

.segment        "STARTUP"
  
  
  lda $c089   ;enable language : card read ROM, write RAM, BANK 1
 
  ;copy the monitor rom on to the language card
  ldax #$f800
  stax copy_src
  stax copy_dest  
  ldax #$0800
  jsr startup_copymem

  
  lda $c08b   ;enable language : card read RAM, write RAM, BANK 1
  lda $c08b   ;this soft switch needs to be read twice 


  ;relocate the CODE segment
  ldax #__CODE_LOAD__
  stax copy_src
  ldax #__CODE_RUN__
  stax copy_dest  
  ldax #__CODE_SIZE__
  jsr startup_copymem


  ;relocate the RODATA segment
  ldax #__RODATA_LOAD__
  stax copy_src
  ldax #__RODATA_RUN__
  stax copy_dest  
  ldax #__RODATA_SIZE__
  jsr startup_copymem

 
;@fixme:  jmp @fixme

  ;relocate the DATA segment
  ldax #__DATA_LOAD__
  stax copy_src
  ldax #__DATA_RUN__
  stax copy_dest  
  ldax #__DATA_SIZE__
  jsr startup_copymem

 ;relocate the IP65_DEFAULTS segment
  ldax #__IP65_DEFAULTS_LOAD__
  stax copy_src
  ldax #__IP65_DEFAULTS_RUN__
  stax copy_dest  
  ldax #__IP65_DEFAULTS_SIZE__
  jsr startup_copymem
 
  jmp init
  
; copy memory
; set copy_src and copy_dest, length in A/X


end: .res 1

startup_copymem:
	sta end
	ldy #0

	cpx #0
	beq @tail

:	lda (copy_src),y
	sta (copy_dest),y
	iny
	bne :-
  inc copy_src+1    ;next page
  inc copy_dest+1  ;next page
	dex
	bne :-

@tail:
	lda end
	beq @done

:	lda (copy_src),y
	sta (copy_dest),y
	iny
	cpy end
	bne :-

@done:
	rts

.code


init:  

  jsr cls

  ldax  #startup_msg
  jsr print
  jsr print_cr


  init_ip_via_dhcp 
  bcc :+
  jmp bad_boot
:  
  jsr print_ip_config
  
  ldx #3
  lda #$FF
: 
;  lda cfg_tftp_server,x
  sta tftp_ip,x
  dex
  bpl :-


  jsr tftp_clear_callbacks
  

  
  ldax #tftp_dir_buffer
  stax tftp_load_address

  ldax #getting_dir_listing_msg
	jsr print


  ldax #tftp_dir_filemask
  stax tftp_filename
  jsr print
  jsr print_cr
  
  jsr tftp_download
	bcs @dir_failed
 
  ldax #$0000   ;load address will be first 2 bytes of file we download (LO/HI order)
  stax tftp_load_address

  ldax  #tftp_dir_buffer
  jsr select_option_from_menu  
  bcc @option_selected
  jmp bad_boot
@option_selected:  
  stax tftp_filename

  ldax #downloading_msg
	jsr print
  
  ldax tftp_filename
  jsr download
  bcc @file_downloaded_ok
  jmp bad_boot

@dir_failed:

  ldax #tftp_dir_listing_fail_msg
  
  jsr print
  jsr print_cr
  
  
  ldax #$0000   ;load address will be first 2 bytes of file we download (LO/HI order)
  stax tftp_load_address

  ldax #downloading_msg
	jsr print

  ldax #tftp_file
  jsr download
  
  bcc @file_downloaded_ok
  jmp bad_boot
  
@file_downloaded_ok:  
  ;set up to jump to where we just d/led the file to
  lda #$4C  ;opcode for JMP
  sta bin_file_jmp
  ldax  tftp_load_address
  stax bin_file_jmp+1
  
  ;but before we go, we need to shift the file down by 2 bytes (to skip over the file length)
  ldax tftp_load_address
  stax  copy_dest
  clc
  adc #02
  bcc :+
  inx
:
  stax  copy_src
  ldy #1
  lda (copy_dest),y ;currently this is the high byte of the length
  tax
  dey
  lda (copy_dest),y   ;currently this is the low byte of the length
  jsr copymem


  ;now make the 'turn off language card' routine
  lda #$AD      ;$AD=LDA
  sta disable_language_card
  lda #$82      ;low byte of soft switch    
  sta disable_language_card+1
  lda #$c0     ;high byte of soft switch
  sta disable_language_card+2
  
  jmp disable_language_card

bad_boot:
  
  jmp $3d0


download:
  stax tftp_filename
  jsr print
  jsr print_cr

  jsr tftp_download  
	bcc :+
  
	ldax #tftp_download_fail_msg
	jsr print
  sec
  rts
  
:
  ldax #tftp_download_ok_msg
	jsr print
  clc
  rts

	.rodata
downloading_msg:  .asciiz "DOWNLOADING "

getting_dir_listing_msg: .asciiz "FETCHING TFTP DIRECTORY FOR "

tftp_dir_listing_fail_msg:
	.asciiz "DIR LISTING FAILED"

tftp_file:  
  .asciiz "BOOTA2.PG2"

tftp_dir_filemask:  
  .asciiz "$*.pg2"

tftp_download_fail_msg:
	.asciiz "DOWNLOAD FAILED"

tftp_download_ok_msg:
	.asciiz "DOWNLOAD OK"

startup_msg: .byte "UTHERNET NETWORK BOOT CLIENT V"

.include "../inc/version.i"
.byte 0



;-- LICENSE FOR utherboot.s --
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
; The Original Code is ip65.
; 
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
