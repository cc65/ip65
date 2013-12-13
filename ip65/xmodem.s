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
PAD = $1A ;padding added to end of file

.export xmodem_receive
.export xmodem_send

.export xmodem_iac_escape ;are IAC bytes ($FF) escaped?

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
.import timer_seconds

.segment "SELF_MODIFIED_CODE"
got_byte:
  jmp $ffff

get_byte:
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
  

emit_a:
;put a byte to the output buffer
;if the byte is $FF, and xmodem_iac_escape is not zero, it is doubled
  jsr @real_emit_a
  cmp #$ff
  bne exit_emit_a
  ldx xmodem_iac_escape
  beq exit_emit_a
@real_emit_a:
emit_a_ptr=*+1
  sta $ffff
  inc emit_a_ptr
  bne :+
  inc emit_a_ptr+1
:
  inc xmodem_block_buffer_length
  bne :+
  inc xmodem_block_buffer_length+1
:
exit_emit_a:
  rts
  
	.bss

original_tcp_callback: .res 2
getc_timeout_end: .res 1
getc_timeout_seconds: .res 1
buffer_length: .res 2

	.code
  
;send a file via XMODEM (checksum mode only, not CRC)
;assumes that a tcp connection has already been set up, and that the other end is waiting to start receiving
;inputs: AX points to routine to call once for each byte in file to send (e.g. save to disk, print to screen, whatever) - byte will be in A, carry flag set means EOF
; xmodem_iac_escape should be set to non-zero if the remote end escapes $FF bytes (i.e. if it is a real telnet server)
;outputs: none
xmodem_send:
  stax get_byte+1
  jsr xmodem_transfer_setup
  lda #0
  sta at_eof

@send_block:
  ldax #sending
  jsr print_ascii_as_native

  ldax #block_number_msg
  jsr print_ascii_as_native
  lda expected_block_number
  jsr print_hex
  jsr print_cr


@wait_for_ack_or_nak:
  lda #XMODEM_TIMEOUT_SECONDS
  jsr getc
  bcs @synch_error
  cmp   #ACK
  beq @got_ack
  cmp   #NAK
  beq @got_nak

@synch_error:
  pha
  lda user_abort
  beq @no_user_abort
  pla
  jmp xmodem_transfer_exit
@no_user_abort:  

  
;flush the input buffer
  lda   #0
  sta   buffer_length
  lda   buffer_length+1

  lda #'('
  jsr print_a
  pla 
  jsr print_hex
  lda #')'
  jsr print_a
  
  inc error_number
  ldax #sync_error_msg
  jsr print_ascii_as_native
  ldax #error_count_msg
  jsr print_ascii_as_native
  lda error_number
  jsr print_hex
  jsr print_cr
  lda error_number
  cmp #XMODEM_MAX_ERRORS
  bcc @wait_for_ack_or_nak
  lda #KPR_ERROR_TOO_MANY_ERRORS
  sta ip65_error
  

  jmp xmodem_transfer_exit

@got_ack:
  inc expected_block_number
  lda at_eof
  bne @send_eot
@got_nak:
  lda #0
  sta checksum
  sta xmodem_block_buffer_length
  sta xmodem_block_buffer_length+1
  ldax #xmodem_block_buffer
  stax emit_a_ptr
  
  lda #SOH
  jsr emit_a
  lda expected_block_number
  jsr emit_a
  eor #$ff
  jsr emit_a
  lda #$80
  sta block_ptr
@copy_one_byte:
  lda at_eof
  bne @add_pad_byte

  jsr get_byte
  bcc @got_byte
  ;sec indicates EOF 
  lda block_ptr
  cmp #$80  ;have we sent any data at all?
  bne @add_pad_byte

@send_eot:
  ;if we get here, we should send an EOT, then read an ACK
  ldax #1
  stax tcp_send_data_len
  ldax #eot_packet
  jsr tcp_send

  lda #XMODEM_TIMEOUT_SECONDS
  jsr getc      ;should be an ACK coming back, doesn't really matter if we don't see it though

  jmp xmodem_transfer_exit
  
@add_pad_byte:
  lda #PAD
@got_byte:  
  pha
  clc
  adc checksum
  sta checksum
  pla
  jsr emit_a
  dec block_ptr
  bne @copy_one_byte
  lda checksum
  jsr emit_a
      
  ldax xmodem_block_buffer_length
  stax tcp_send_data_len
  ldax #xmodem_block_buffer
  jsr tcp_send
  bcc @send_ok
  ldax #send_error
  jsr print_ascii_as_native
  lda ip65_error
  jsr print_hex
  jsr print_cr
@send_ok:  
  jmp @send_block

  rts


  
xmodem_transfer_setup:
  lda #0
  sta buffer_length
  sta buffer_length+1
  sta error_number
  sta user_abort
  lda #1
  sta expected_block_number
  

  ldax tcp_callback
  stax original_tcp_callback
  ldax #xmodem_tcp_callback
  stax tcp_callback 
  rts
  

;recieve a file via XMODEM (checksum mode only, not CRC)
;assumes that a tcp connection has already been set up, and that the other end is waiting to start sending
;inputs: AX points to routine to call once for each byte in downloaded file (e.g. save to disk, print to screen, whatever) - byte will be in A
; xmodem_iac_escape should be set to non-zero if the remote end escapes $FF bytes (i.e. if it is a real telnet server)
;outputs: none
xmodem_receive:
  
  stax got_byte+1
  jsr xmodem_transfer_setup
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
  sec
  jmp xmodem_transfer_exit
@no_user_abort:  
  jsr send_nak
  inc error_number
  ldax #timeout_msg
  jsr print_ascii_as_native
  ldax #error_count_msg
  jsr print_ascii_as_native
  lda error_number
  jsr print_hex
  jsr print_cr
  lda error_number
  cmp #XMODEM_MAX_ERRORS
  bcc @wait_for_block_start
  lda #KPR_ERROR_TOO_MANY_ERRORS
  sta ip65_error
  jmp xmodem_transfer_exit
@got_block_start:
  cmp #EOT
  bne :+
  ldax #got_eot
  jsr print_ascii_as_native

  jsr send_ack
  clc
  jmp xmodem_transfer_exit
:  
    
  cmp #$81 ;jamming signal BBS seems to use $81 not $01 as SOH
  beq @got_soh
  cmp #SOH
  beq @got_soh
  lda #'!'  ;we got an unexpected character
  jsr print_a
  jsr print_hex
  ;we need to clear the input buffer
@clear_input_buffer:  
  lda #'!'  ;we got an unexpected character
  jsr print_a
  lda #1
  jsr getc
  bcc @clear_input_buffer  
  

  jmp @wait_for_block_start
@got_soh:
  ;now get block number
  lda #XMODEM_TIMEOUT_SECONDS
  jsr getc
  bcc :+
  jsr send_nak
  lda #'.'
  jmp print_a
  jmp @wait_for_block_start
:
  sta actual_block_number
  
  ;now get block number check
  lda #XMODEM_TIMEOUT_SECONDS
  jsr getc
  bcc :+
  lda #'.'
  jmp print_a
  jsr send_nak
  jmp @wait_for_block_start
:
  adc actual_block_number
  cmp #$ff
  beq :+
  lda #'?'
  jsr print_a  
  jmp @wait_for_block_start
:  
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
  bcc :+
  jmp xmodem_transfer_exit
:  
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
  bcs xmodem_transfer_exit
  sta received_checksum
  jsr print_hex
  jsr print_cr
  
  lda received_checksum
  cmp checksum
  beq @checksum_ok
  ;checksum error :-(
  inc error_number
  ldax #checksum_error_msg
  jsr print_ascii_as_native
  ldax #error_count_msg
  jsr print_ascii_as_native
  lda error_number
  jsr print_hex
  jsr print_cr
  lda error_number
  cmp #XMODEM_MAX_ERRORS
  bcs :+
  jmp @wait_for_block_start
:  
  lda #KPR_ERROR_TOO_MANY_ERRORS
  sta ip65_error
  jmp xmodem_transfer_exit

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

xmodem_transfer_exit:
  ldax original_tcp_callback
  stax tcp_callback
  
  rts

xmodem_tcp_callback:
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
  jsr copymem
  rts
  
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
  jsr @real_getc
  bcc :+  ;of we got an error, then bail
  rts
:  
  cmp #$ff
  beq @got_ff
  clc
  rts
@got_ff:    
  lda xmodem_iac_escape
  bne @real_getc  ;need to skip over the $FF and go read another byte
  lda #$ff
  clc
  rts
  
@real_getc:
  sta getc_timeout_seconds

  clc
  jsr timer_seconds  ;time of day clock: seconds (in BCD)
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
  jsr timer_seconds  ;time of day clock: seconds
  cmp getc_timeout_end  
  bne @poll_loop
  lda #00
  sec
  rts
  
  

.rodata
  ack_packet: .byte ACK
  nak_packet: .byte NAK
  eot_packet: .byte EOT
  
block_number_msg: .byte " block $",0
expecting: .byte "expecting",0
receiving: .byte "receiving",0
sending: .byte "sending",0
got_eot: .byte "end of transmission",10,0

bad_block_number: .byte "bad block number",0
checksum_msg: .byte "checksum $",0
checksum_error_msg : .byte "checksum",0 
timeout_msg: .byte "timeout error",0
sync_error_msg: .byte "sync",0
error_count_msg: .byte " error - error count $",0
send_error: .byte " send error - $",0

.segment "APP_SCRATCH"
xmodem_stream_buffer: .res 1600
xmodem_block_buffer: .res 300
xmodem_block_buffer_length: .res 2
expected_block_number: .res 1
actual_block_number: .res 1
checksum: .res 1
received_checksum: .res 1
block_ptr: .res 1
error_number: .res 1
user_abort: .res 1
xmodem_iac_escape: .res 1
at_eof: .res 1
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
