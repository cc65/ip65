; XMODEM file transfer

.include "../inc/common.i"
.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif
  

XMODEM_BLOCK_SIZE=$80  ;how many bytes (excluding header & checksum) in each block?
XMODEM_TIMEOUT_SECONDS=5
XMODEM_MAX_ERRORS=10
SOH = $01
EOT = $04
ACK = $06
NAK = $15
CAN = $18

.export xmodem_receive

.import ip65_process
.import ip65_error
.import tcp_callback
.import copymem
.importzp copy_src
.importzp copy_dest
.import tcp_send
.import tcp_send_data_len
.import tcp_inbound_data_ptr
.import tcp_inbound_data_length
.import check_for_abort_key
.import print_a
.import print_cr
.import print_ascii_as_native
.import print_hex

.segment "SELF_MODIFIED_CODE"
got_byte:
  jmp $ffff

next_char:
  lda buffer_length
  bne @not_eof
  lda buffer_length+1
  bne @not_eof
  sec
  rts
@not_eof:  
  next_char_ptr=*+1
  lda $ffff
  pha
  inc next_char_ptr
  bne :+
  inc next_char_ptr+1
:  
  sec
  lda   buffer_length
  sbc #1
  sta   buffer_length
  lda   buffer_length+1
  sbc #0
  sta   buffer_length+1
  pla
  clc
  
  rts
	.bss

original_tcp_callback: .res 2
getc_timeout_end: .res 1
getc_timeout_seconds: .res 1
buffer_length: .res 2

	.code
 
xmodem_receive:
;recieve a file via XMODEM (checksum mode only, not CRC)
;assumes that a tcp connection has already been set up, and that the other end is waiting to start sending
;inputs: AX points to routine to call once for each byte in downloaded file (e.g. save to disk, print to screen, whatever) - byte will be in A
;outputs: none

  
  stax got_byte+1
  lda #0
  sta buffer_length
  sta buffer_length+1
  sta error_number
  sta user_abort
  lda #1
  sta expected_block_number
  

  ldax tcp_callback
  stax original_tcp_callback
  ldax #xmodem_receive_callback
  stax tcp_callback 
  jsr send_nak  


@next_block:  
  lda #0
  sta block_ptr
  sta checksum
  ldax #expecting
  jsr print_ascii_as_native

  ldax #block_number_msg
  jsr print_ascii_as_native
  lda expected_block_number
  jsr print_hex
  jsr print_cr

@wait_for_block_start:
  lda #XMODEM_TIMEOUT_SECONDS
  jsr getc
  bcc @got_block_start
  lda user_abort
  beq @no_user_abort
  jmp @exit
@no_user_abort:  
  jsr send_nak
  inc error_number
  ldax #timeout_msg
  jsr print_ascii_as_native
  lda error_number
  jsr print_hex
  jsr print_cr
  lda error_number
  cmp #XMODEM_MAX_ERRORS
  bcc @wait_for_block_start
  lda #KPR_ERROR_TOO_MANY_ERRORS
  sta ip65_error
  jmp @exit
@got_block_start:
  cmp #EOT
  bne :+
  jsr send_ack
  clc
  jmp @exit
:  
  cmp #SOH
  bne @wait_for_block_start

  ;now get block number
  lda #XMODEM_TIMEOUT_SECONDS
  jsr getc
  bcc :+
  jsr send_nak
  jmp @wait_for_block_start
:
  sta actual_block_number
  
  ;now get block number check
  lda #XMODEM_TIMEOUT_SECONDS
  jsr getc
  bcc :+
  jsr send_nak
  jmp @wait_for_block_start
:
  adc actual_block_number
  cmp #$ff
  bne @wait_for_block_start
  ldax #receiving
  jsr print_ascii_as_native

  ldax #block_number_msg
  jsr print_ascii_as_native
  lda actual_block_number
  jsr print_hex
  jsr print_cr
  
@next_byte:
  lda #XMODEM_TIMEOUT_SECONDS
  jsr getc
  bcs @exit
  ldx block_ptr
  sta xmodem_block_buffer,x
  adc checksum
  sta checksum
  
  inc block_ptr
  lda block_ptr
  bpl @next_byte
  
  ldax #checksum_msg
  jsr print_ascii_as_native
  lda checksum
  jsr print_hex
  
  lda #'/'
  jsr print_a
  
  lda #XMODEM_TIMEOUT_SECONDS
  jsr getc
  bcs @exit
  sta received_checksum
  jsr print_hex
  jsr print_cr
  
  lda received_checksum
  cmp checksum
  beq @checksum_ok
  jsr send_nak
  jmp @next_block

@checksum_ok:
  lda expected_block_number
  cmp actual_block_number
  bne @skip_block_output

  lda #0
  sta block_ptr

@output_byte:
  ldx block_ptr
  lda xmodem_block_buffer,x
  jsr got_byte
  inc block_ptr
  lda block_ptr
  bpl @output_byte

  inc expected_block_number

@skip_block_output:
  jsr send_ack
  jmp @next_block

  clc
@exit:  
  ldax original_tcp_callback
  stax tcp_callback
  
  rts

xmodem_receive_callback:
  lda tcp_inbound_data_length+1
  cmp #$ff
  bne @not_eof
  rts
@not_eof:
  
  ldax tcp_inbound_data_ptr
  stax copy_src
  ldax #xmodem_stream_buffer
  stax copy_dest
  stax next_char_ptr

  ldax tcp_inbound_data_length
  stax buffer_length
  jmp copymem

  
send_nak:
  ldax #1
  stax tcp_send_data_len
  ldax #nak_packet
  jmp tcp_send

send_ack:
  ldax #1
  stax tcp_send_data_len
  ldax #ack_packet
  jmp tcp_send


getc:
  sta getc_timeout_seconds

  clc
  lda $dc09  ;time of day clock: seconds (in BCD)
  sed
  adc getc_timeout_seconds
  cmp #$60
  bcc @timeout_set
  sec
  sbc #$60
@timeout_set:  
  cld
  sta getc_timeout_end  

@poll_loop: 
;  inc $d021
  jsr next_char
  bcs @no_char
  rts ;done!
@no_char:  
  jsr check_for_abort_key
  bcc @no_abort
  lda #KPR_ERROR_ABORTED_BY_USER
  sta ip65_error
  inc user_abort
  rts
@no_abort:  
  jsr ip65_process
  lda $dc09  ;time of day clock: seconds
  cmp getc_timeout_end  
  bne @poll_loop
  sec
  rts
  
  

.rodata
  ack_packet: .byte ACK
  nak_packet: .byte NAK

block_number_msg: .byte " block $",0
expecting: .byte "expecting",0
receiving: .byte "receiving",0
bad_block_number: .byte "bad block number",0
checksum_msg: .byte "checksum $",0
timeout_msg: .byte "timeout $",0

.segment "APP_SCRATCH"
xmodem_stream_buffer: .res 1600
xmodem_block_buffer: .res 128
expected_block_number: .res 1
actual_block_number: .res 1
checksum: .res 1
received_checksum: .res 1
block_ptr: .res 1
error_number: .res 1
user_abort: .res 1

;-- LICENSE FOR xmodem.s --
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
