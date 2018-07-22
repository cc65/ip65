; routine for downloading a URL

.include "zeropage.inc"
.include "../inc/common.inc"

TIMEOUT_SECONDS = 15

.importzp copy_src
.importzp copy_dest
.import copymem
.import timer_read
.import ip65_process
.import tcp_connect
.import tcp_send_string
.import tcp_send_data_len
.import tcp_callback
.import tcp_close
.import tcp_connect_ip
.import tcp_inbound_data_length
.import tcp_inbound_data_ptr
.import url_ip
.import url_port
.import url_selector
.import url_parse

.export url_download
.export url_download_buffer
.export url_download_buffer_length
.export resource_download
.export resource_buffer


.bss

  src_ptr:                      .res 1
  dest_ptr:                     .res 1
  timeout_counter:              .res 1
  url_download_buffer:          .res 2  ; points to a buffer that url will be downloaded into
  url_download_buffer_length:   .res 2  ; length of buffer that url will be downloaded into

  resource_buffer:          .res 2
  resource_buffer_length:   .res 2

  download_flag: .res 1


.code

; download a resource specified by an URL
; inputs:
; AX = address of URL string
; url_download_buffer - points to a buffer that url will be downloaded into
; url_download_buffer_length - length of buffer
; outputs:
; sec if an error occured, else buffer pointed at by url_download_buffer is filled with contents
; of specified resource (with an extra 2 null bytes at the end),
; AX = length of resource downloaded.
url_download:
  jsr url_parse
  bcc resource_download
  rts

; download a resource specified by ip,port & selector
; inputs:
; url_ip = ip address of host to connect to
; url_port = port number of to connect to
; url_selector= address of selector to send to host after connecting
; url_download_buffer - points to a buffer that url will be downloaded into
; url_download_buffer_length - length of buffer
; outputs:
; sec if an error occured, else buffer pointed at by url_download_buffer is filled with contents
; of specified resource (with an extra 2 null bytes at the end).
resource_download:
  ldax url_download_buffer
  stax resource_buffer
  ldax url_download_buffer_length
  stax resource_buffer_length
  jsr put_zero_at_end_of_dl_buffer

  ldx #3                        ; save IP address just retrieved
: lda url_ip,x
  sta tcp_connect_ip,x
  dex
  bpl :-
  ldax #url_download_callback
  stax tcp_callback

  ldax url_port
  jsr tcp_connect
  bcs @error

  ; connected, now send the selector
  ldx #0
  stx download_flag
  ldax url_selector

  jsr tcp_send_string
  jsr timer_read
  txa
  adc #TIMEOUT_SECONDS*4        ; what value should trigger the timeout?
  sta timeout_counter
  ; now loop until we're done
@download_loop:
  jsr ip65_process
  jsr timer_read
  cpx timeout_counter
  beq @timeout
  lda download_flag
  beq @download_loop
@timeout:
  jsr tcp_close
  clc
@error:
  rts

url_download_callback:
  lda tcp_inbound_data_length+1
  cmp #$ff
  bne not_end_of_file
@end_of_file:
  lda #1
  sta download_flag

put_zero_at_end_of_dl_buffer:
  ; put a zero byte at the end of the file
  ldax resource_buffer
  stax ptr2
  lda #0
  tay
  sta (ptr2),y
  rts

not_end_of_file:
  ; copy this chunk to our input buffer
  ldax resource_buffer
  stax copy_dest
  ldax tcp_inbound_data_ptr
  stax copy_src
  sec
  lda resource_buffer_length
  sbc tcp_inbound_data_length
  pha
  lda resource_buffer_length+1
  sbc tcp_inbound_data_length+1
  bcc @would_overflow_buffer
  sta resource_buffer_length+1
  pla
  sta resource_buffer_length
  ldax tcp_inbound_data_length
  jsr copymem
  ; increment the pointer into the input buffer
  clc
  lda resource_buffer
  adc tcp_inbound_data_length
  sta resource_buffer
  lda resource_buffer+1
  adc tcp_inbound_data_length+1
  sta resource_buffer+1
  jmp put_zero_at_end_of_dl_buffer

@would_overflow_buffer:
  pla ; clean up the stack
  ldax resource_buffer_length
  jsr copymem
  lda resource_buffer
  adc resource_buffer_length
  sta resource_buffer
  lda resource_buffer+1
  adc resource_buffer_length+1
  sta resource_buffer+1
  lda #0
  sta resource_buffer_length
  sta resource_buffer_length+1
  jmp put_zero_at_end_of_dl_buffer



; -- LICENSE FOR download.s --
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
