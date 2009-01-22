;#############
; 
; This will boot a C64 with RR-NET from the network
; requires
; 1) a DHCP server, and
; 2) a TFTP server that responds to requests on the broadcast address (255.255.255.255) and that will serve a file called 'BOOTC64.PRG'.
; the prg file can be either BASIC or M/L, and up to 30K in length.
;
; jonno@jamtronix.com - January 2009
;

  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  

  .importzp tftp_filename
  .import tftp_load_address
  .import tftp_ip  
  .import tftp_download
  .import cfg_tftp_server

	.import copymem
	.importzp copy_src
	.importzp copy_dest

  .import  __DATA_LOAD__
  .import  __DATA_RUN__
  .import  __DATA_SIZE__

	.bss

;temp_bin: .res 1
;temp_bcd: .res 2

bin_file_jmp: .res 3

.segment "CARTRIDGE_HEADER"
.word init  ;cold start vector
.word init  ;warm start vector
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
  jsr $e453   ;set BASIC vectors
  jsr $e3bf   ;initialize zero page

  ldax  #startup_msg
  jsr print
 
  ;relocate our r/w data
  ldax #__DATA_LOAD__
  stax copy_src
  ldax #__DATA_RUN__
  stax copy_dest
  ldax #__DATA_SIZE__
  jsr copymem



  init_ip_via_dhcp 
  
	
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
                          ;check whether the file we just downloaded was a BASIC prg
  lda tftp_load_address
  cmp #01
  bne @not_a_basic_file
  lda tftp_load_address+1
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
  jmp $a7ae  ; jump to BASIC interpreter loop 
  
@not_a_basic_file:
  lda #$4C  ;opcode for JMP
  sta bin_file_jmp
  ldax  tftp_load_address
  stax bin_file_jmp+1
  jsr bin_file_jmp
  rts


bad_boot:
  jmp bad_boot


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

startup_msg: .byte "RR-NET NETWORK BOOK CLIENT V0.1",13,0

downloading_msg:  .asciiz "DOWNLOADING "

tftp_file:  
  .asciiz "BOOTC64.PRG"

tftp_download_fail_msg:
	.byte "DOWNLOAD FAILED", 13, 0

tftp_download_ok_msg:
	.byte "DOWNLOAD OK", 13, 0
  

  