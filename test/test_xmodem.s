  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"

  .import parse_dotted_quad
  .import dotted_quad_value
  
  .import tcp_listen
  .import tcp_callback
  .import ip65_error
  .import get_key_ip65

  .import tcp_connect
  .import tcp_connect_ip

  .import tcp_inbound_data_ptr
  .import tcp_inbound_data_length

  .import xmodem_send
  .import xmodem_receive
  .import xmodem_iac_escape
  
  .import tcp_send
  .import tcp_send_data_len
  .import tcp_send_string
  .import tcp_close
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__
  .import  __DATA_SIZE__
  

	.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

	.word basicstub		; load address

basicstub:
	.word @nextline
	.word 2003
	.byte $9e
	.byte <(((init / 1000) .mod 10) + $30)
	.byte <(((init / 100 ) .mod 10) + $30)
	.byte <(((init / 10  ) .mod 10) + $30)
	.byte <(((init       ) .mod 10) + $30)
	.byte 0
@nextline:
	.word 0

.segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-$11                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; Size
        jmp init

.bss 
packet_count: .res 1
.code

init:

  
  lda #14
  jsr print_a ;switch to lower case 
    
    
  lda #1
;  lda #0
  sta xmodem_iac_escape
  lda #0    
  sta $dc08 ;set deciseconds - starts TOD going 
  jsr print_cr
  init_ip_via_dhcp 
  jsr print_ip_config

  ldax #starting
  jsr print_ascii_as_native
  jsr print_cr

   
  ;connect to port 1000 - xmodem server

  ldax  #tcp_callback_routine
  stax  tcp_callback
  ldax  tcp_dest_ip
  stax  tcp_connect_ip
  ldax  tcp_dest_ip+2
  stax  tcp_connect_ip+2
    
  lda #0
  sta packet_count
  ldax  #1000
  jsr tcp_connect
  
  bcc :+
  jmp check_for_error
:  
  
  ldax #first_message
  jsr tcp_send_string
:  
  jsr ip65_process
  lda packet_count
  beq :-

  ldax #connected
  jsr print_ascii_as_native
  jsr download_file
  jsr check_for_error
  jsr upload_file
  jsr check_for_error
  jsr tcp_close
  rts

upload_file:
  ldax #uploading
  jsr print_ascii_as_native
  
  ldax #start_upload
  jsr tcp_send_string
  bcc :+
@error:
  jsr check_for_error
:

  jsr open_upload_file
  bcc :+
  jmp check_for_error
:  
  ldax #read_byte
  jsr xmodem_send
  jsr close_file  
  
  rts

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

eof: .byte $0


download_file:
  ldax #downloading
  jsr print_ascii_as_native
  
  ldax #start_download
  jsr tcp_send_string
  bcc :+
@error:
  jsr check_for_error
:

  jsr open_download_file
  bcc :+
  jmp check_for_error
:  
  ldax #write_byte
  jsr xmodem_receive
  jsr close_file
  
    
  rts


tcp_callback_routine:

  inc packet_count
  rts

  


check_for_error:
  lda ip65_error
  beq @exit
  ldax #error_code
  jsr print
  lda ip65_error
  jsr  print_hex
  jsr print_cr
  lda #0
  sta ip65_error
@exit:  
  rts



@error:
  ldax  #failed_msg
  jsr print
  jsr print_cr
  rts
  

open_upload_file:  
  lda #upload_filename_end-upload_filename
  ldx #<upload_filename
  ldy #>upload_filename
  jmp open_file
  
open_download_file:  
  lda #download_filename_end-download_filename
  ldx #<download_filename
  ldy #>download_filename

open_file:
  jsr $FFBD     ; call SETNAM
  lda #$02      ; file number 2
  ldx $BA       ; last used device number
  bne @skip
.import cfg_default_drive  
  ldx cfg_default_drive
@skip:

  
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
  
  
  .bss
  temp_ax: .res 2
  
	.rodata

starting: 
.byte "saving to "
download_filename:  .byte "@0:XMODEM.TMP,P,W"  ; @0: means 'overwrite if existing', ',P,W' is required to make this an output file
download_filename_end:
.byte 0
first_message:
  .byte "yo!",0

upload_filename:  .byte "XMODEM.TMP"  
upload_filename_end:
.byte 0

start_download: 
  .byte "B",0   ;B=Binary, i.e. trigger IAC escape, R=receive text, i.e. no IAC escape
.data

start_upload: 
  .byte "S",0   ;S send via normal checksum mode (not CRC)
.data

uploading: .byte "uploading",10,0
downloading: .byte "downloading",10,0
connected: .byte "connected",10,0
tcp_dest_ip:
  .byte 10,5,1,102
;  .byte 192,168,160,1
  
 
 

;-- LICENSE FOR test_xmodem.s --
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
