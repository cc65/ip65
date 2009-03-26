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
  .include "../inc/menu.i"
  .import cls
  .import get_key
  .import beep


  .importzp tftp_filename
  .import tftp_load_address
  .import tftp_ip
  .import tftp_download
  .import tftp_directory_listing 

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
tftp_dir_buffer: .res 2000


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

  ;switch to lower case charset
  lda #23
  sta $d018


  
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
    bcc :+
  jmp bad_boot
:  
  jsr print_ip_config

    ldx #3
: 
  lda cfg_tftp_server,x
  sta tftp_ip,x
  dex
  bpl :-


  ldax #tftp_dir_buffer
  stax tftp_load_address

  ldax #getting_dir_listing_msg
	jsr print

  ldax #tftp_dir_filemask
  stax tftp_filename
  jsr print
  jsr print_cr

  jsr tftp_directory_listing 
	bcs @dir_failed

  ldax #$0000   ;load address will be first 2 bytes of file we dowload (LO/HI order)
  stax tftp_load_address

  ldax  #tftp_dir_buffer
  jsr select_option_from_menu  
  stax tftp_filename


  ldax #downloading_msg
	jsr print


  ldax tftp_filename
  jsr download
  bcc @file_downloaded_ok
@dir_failed:  
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
  ldax  #failed_msg
  jmp print   ;this will also exit


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

startup_msg: .byte "NETBOOT65 - C64 NETWORK BOOT CLIENT V0.1",13,0

downloading_msg:  .asciiz "DOWNLOADING "

getting_dir_listing_msg: .asciiz "FETCHING TFTP DIRECTORY FOR "

tftp_dir_listing_fail_msg:
	.asciiz "DIR LISTING FAILED"

tftp_download_fail_msg:
	.byte "DOWNLOAD FAILED", 13, 0

tftp_download_ok_msg:
	.byte "DOWNLOAD OK", 13, 0
  
tftp_dir_filemask:  
  .asciiz "*.PRG"
