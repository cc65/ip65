; Simple Network Time Protocol implementation - per RFC 2030

MAX_SNTP_MESSAGES_SENT = 8

.include "../inc/common.inc"
.include "../inc/error.inc"

.export sntp_ip
.export sntp_utc_timestamp
.export sntp_get_time

.import ip65_process
.import ip65_error

.import udp_add_listener
.import udp_remove_listener

.import udp_callback
.import udp_send

.import udp_inp
.import output_buffer
.importzp udp_data

.import udp_send_dest
.import udp_send_src_port
.import udp_send_dest_port
.import udp_send_len
.import check_for_abort_key
.import timer_read


.data

sntp_ip: .byte $ff,$ff,$ff,$ff  ; can be set to ip address of server that will be queried via sntp (default is a local LAN broadcast)


.bss

; sntp packet offsets
sntp_inp = udp_inp + udp_data

sntp_server_port = 123
sntp_client_port = 123

sntp_utc_timestamp: .res 4      ; will be set to seconds (only) part of utc timestamp (seconds since 00:00 on Jan 1, 1900)

; sntp state machine
sntp_initializing = 1           ; initial state
sntp_query_sent   = 2           ; sent a query, waiting for a response
sntp_completed    = 3           ; got a good response

sntp_timer:              .res 1
sntp_loop_count:         .res 1
sntp_break_polling_loop: .res 1

sntp_state:              .res 1
sntp_message_sent_count: .res 1


.code

; query an sntp server for current UTC time
; inputs:
; sntp_ip must point to an SNTP server
; outputs:
; carry flag is set if there was an error, clear otherwise
; sntp_utc_timestamp: set to the number of seconds (seconds since 00:00 on Jan 1, 1900) - timezone is UTC
sntp_get_time:
  ldax #sntp_in
  stax udp_callback
  ldax #sntp_client_port
  jsr udp_add_listener
  bcc :+
  rts
: lda #sntp_initializing
  sta sntp_state
  lda #0                        ; reset the "message sent" counter
  sta sntp_message_sent_count
  jsr send_sntp_query

@sntp_polling_loop:
  lda sntp_message_sent_count
  adc #10
  sta sntp_loop_count
@outer_delay_loop:
  lda #0
  sta sntp_break_polling_loop
  jsr timer_read
  stx sntp_timer                ; we only care about the high byte

@inner_delay_loop:
  jsr ip65_process
  jsr check_for_abort_key
  bcc @no_abort
  lda #IP65_ERROR_ABORTED_BY_USER
  sta ip65_error
  rts
@no_abort:
  lda sntp_state
  cmp #sntp_completed
  beq @complete

  lda sntp_break_polling_loop
  bne @break_polling_loop
  jsr timer_read
  cpx sntp_timer                ; this will tick over after about 1/4 of a second
  beq @inner_delay_loop

  dec sntp_loop_count
  bne @outer_delay_loop

@break_polling_loop:
  jsr send_sntp_query
  inc sntp_message_sent_count
  lda sntp_message_sent_count
  cmp #MAX_SNTP_MESSAGES_SENT-1
  bpl @too_many_messages_sent
  jmp @sntp_polling_loop

@complete:
  ldax #sntp_client_port
  jsr udp_remove_listener
  rts

@too_many_messages_sent:
@failed:
  ldax #sntp_client_port
  jsr udp_remove_listener
  lda #IP65_ERROR_TIMEOUT_ON_RECEIVE
  sta ip65_error
  sec                           ; signal an error
  rts

send_sntp_query:
  ; make a zero filled buffer
  lda #$0
  ldx #$30
  stx udp_send_len
  sta udp_send_len+1
: sta output_buffer,x
  dex
  bpl :-

  ; set the flags field
  lda #$E3                      ; flags - LI=11 (unknown), VN=100 (4), MODE=011 (client)
  sta output_buffer

  ldax #sntp_client_port
  stax udp_send_src_port
  ldax #sntp_server_port
  stax udp_send_dest_port
  ldx #3                        ; set destination address
: lda sntp_ip,x
  sta udp_send_dest,x
  dex
  bpl :-

  ldax #output_buffer
  jsr udp_send
  bcs @error_on_send
  lda #sntp_query_sent
  sta sntp_state
@error_on_send:
  rts

sntp_in:
  ldx #3
  ldy #0
: lda sntp_inp+$28,x            ; the 'transmit' timestamp (in big end order)
  sta sntp_utc_timestamp,y
  iny
  dex
  bpl :-

  inc sntp_break_polling_loop
  lda #sntp_completed
  sta sntp_state
  rts



; -- LICENSE FOR sntp.s --
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
; Portions created by the Initial Developer are Copyright (C) 2009,2011
; Jonno Downes. All Rights Reserved.
; -- LICENSE END --
