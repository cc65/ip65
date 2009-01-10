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
  .import cls
	
  .importzp tftp_filename
  .import tftp_load_address
  .import tftp_ip
  .import tftp_download

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
  
	.bss

temp_bin: .res 1
temp_bcd: .res 2

end: .res 1

bin_file_jmp: .res 3

; ------------------------------------------------------------------------

        .segment        "EXEHDR"

        .addr           __STARTUP_LOAD__                ; Start address
        .word           __STARTUP_SIZE__+__CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; Size

; ------------------------------------------------------------------------


.segment        "STARTUP"
  
  
  lda $c089   ;enable language : card read ROM, write RAM, BANK 1
 
  ;copy the monitor rom on to the language card
  
  ;relocate the RODATA segment
  ldax #$f800
  stax copy_src
  stax copy_dest  
  ldax #$0800
  jsr startup_copymem

  ;relocate the RODATA segment
  ldax #__RODATA_LOAD__
  stax copy_src
  ldax #__RODATA_RUN__
  stax copy_dest  
  ldax #__RODATA_SIZE__
  jsr startup_copymem

  ;relocate the DATA segment
  ldax #__DATA_LOAD__
  stax copy_src
  ldax #__DATA_RUN__
  stax copy_dest  
  ldax #__DATA_SIZE__
  jsr startup_copymem

  ;relocate the CODE segment
  ldax #__CODE_LOAD__
  stax copy_src
  ldax #__CODE_RUN__
  stax copy_dest  
  ldax #__CODE_SIZE__
  jsr startup_copymem
  
  lda $c08b   ;enable language : card read RAM, write RAM, BANK 1
  lda $c08b   ;this soft switch needs to be read twice 
  jmp init
  
; copy memory
; set copy_src and copy_dest, length in A/X
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
  bcs bad_boot
  jsr print_ip_config
  
  ldx #3
: 
  lda cfg_tftp_server,x
  sta tftp_ip,x
  dex
  bpl :-

  ldax #$0000   ;load address will be first 2 bytes of file we dowload (LO/HI order)
  stax tftp_load_address

  ldax #downloading_msg
	jsr print

  ldax #tftp_file
  jsr download
  
  bcc @file_downloaded_ok
  jmp bad_boot
  
@file_downloaded_ok:  

  lda #$4C  ;opcode for JMP
  sta bin_file_jmp
  ldax  tftp_load_address
  stax bin_file_jmp+1
  jsr bin_file_jmp
  jmp $3d0

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

tftp_file:  
  .asciiz "BOOTA2.BIN"

tftp_download_fail_msg:
	.asciiz "DOWNLOAD FAILED"

tftp_download_ok_msg:
	.asciiz "DOWNLOAD OK"

startup_msg: .byte "UTHERNET NETWORK BOOT CLIENT V0.1",0
