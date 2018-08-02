; routine for parsing a URL

.include "zeropage.inc"
.include "../inc/common.inc"
.include "../inc/error.inc"

.import output_buffer
.import ip65_error
.import parser_init
.import parser_skip_next
.import dns_set_hostname
.import dns_resolve
.import parse_integer
.import dns_ip

.export url_ip
.export url_port
.export url_selector
.export url_resource_type
.export url_parse

search_string   = ptr1
selector_buffer = output_buffer


.bss

  url_string:           .res 2
  url_ip:               .res 4  ; will be set with ip address of host in url
  url_port:             .res 2  ; will be set with port number of url
  url_selector:         .res 2  ; will be set with address of selector part of URL
  url_type:             .res 1
  url_resource_type:    .res 1
  url_type_unknown = 0
  url_type_gopher  = 1
  url_type_http    = 2

  src_ptr:              .res 1
  dest_ptr:             .res 1


.code

; parses a URL into a form that makes it easy to retrieve the specified resource
; inputs:
; AX = address of URL string
; any control character (i.e. <$20) is treated as 'end of string', e.g. a CR or LF, as well as $00
; outputs:
; sec if a malformed url, otherwise:
; url_ip = ip address of host in url
; url_port = port number of url
; url_selector= address of selector part of URL
url_parse:
  stax url_string
  ldy #url_type_http
  sty url_type
  ldy #80
  sty url_port
  ldy #0
  sty url_port+1
  sty url_resource_type

  jsr skip_to_hostname
  bcc :+
  ldax url_string
  jmp @no_protocol_specifier
: ldax url_string
  stax search_string

  lda (search_string),y
  cmp #'g'
  beq @gopher
  cmp #'G'
  beq @gopher
  cmp #'h'
  beq @protocol_set
  cmp #'H'
  beq @protocol_set
@exit_with_error:
  lda #IP65_ERROR_MALFORMED_URL
  sta ip65_error
@exit_with_sec:
  sec
  rts
@gopher:
lda #url_type_gopher
  sta url_type
  lda #70
  sta url_port
@protocol_set:
  jsr skip_to_hostname
  ; now pointing at hostname
  bcs @exit_with_error
@no_protocol_specifier:
  jsr dns_set_hostname
  bcs @exit_with_sec
  jsr dns_resolve
  bcc :+
  lda #IP65_ERROR_DNS_LOOKUP_FAILED
  sta ip65_error
  jmp @exit_with_sec
: ; copy IP address
  ldx #3
: lda dns_ip,x
  sta url_ip,x
  dex
  bpl :-

  jsr skip_to_hostname

  ; skip over next colon
  ldax #colon
  jsr parser_skip_next
  bcs @no_port_in_url
  ; AX now point at first thing past a colon - should be a number:
  jsr parse_integer
  stax url_port
@no_port_in_url:
  ; skip over next slash
  ldax #slash
  jsr parser_skip_next
  bcc :+
  ; No slash at all after hostname -> empty selector
  ldax #zero
: ; AX now pointing at selector
  stax ptr1
  ldax #selector_buffer
  stax ptr2
  lda #0
  sta src_ptr
  sta dest_ptr
  lda url_type

  cmp #url_type_gopher
  bne @not_gopher
  ; first byte after / in a gopher url is the resource type
  ldy src_ptr
  lda (ptr1),y
  beq @start_of_selector
  sta url_resource_type
  inc src_ptr
  jmp @start_of_selector
@not_gopher:
  cmp #url_type_http
  beq @build_http_request
  jmp @done                     ; if it's not gopher or http, we don't know how to build a selector
@build_http_request:
  ldy #get_length-1
  sty dest_ptr
: lda get,y
  sta (ptr2),y
  dey
  bpl :-

@start_of_selector:
  lda #'/'
  inc dest_ptr
  jmp @save_first_byte_of_selector
@copy_one_byte:
  ldy src_ptr
  lda (ptr1),y
  cmp #$20
  bcc @end_of_selector          ; any control char (including CR,LF, and $00) should be treated as end of URL
  inc src_ptr
@save_first_byte_of_selector:
  ldy dest_ptr
  sta (ptr2),y
  inc dest_ptr
  bne @copy_one_byte
@end_of_selector:
  ldx #1                        ; number of CRLF at end of gopher request
  lda url_type

  cmp #url_type_http
  bne @final_crlf

  ; now the HTTP version number & Host: field
  ldx #0
: lda http_preamble,x
  beq :+
  ldy dest_ptr
  inc dest_ptr
  sta (ptr2),y
  inx
  bne :-
: ; now copy the host field
  jsr skip_to_hostname
  ; AX now pointing at hostname
  stax ptr1
  ldax #selector_buffer
  stax ptr2

  lda #0
  sta src_ptr

@copy_one_byte_of_hostname:
  ldy src_ptr
  lda (ptr1),y
  beq @end_of_hostname
  cmp #':'
  beq @end_of_hostname
  cmp #'/'
  beq @end_of_hostname
  inc src_ptr
  ldy dest_ptr
  sta (ptr2),y
  inc dest_ptr
  bne @copy_one_byte_of_hostname
@end_of_hostname:
  ldx #2                        ; number of CRLF at end of HTTP request

@final_crlf:
  ldy dest_ptr
  lda #$0d
  sta (ptr2),y
  iny
  lda #$0a
  sta (ptr2),y
  iny
  sty dest_ptr
  dex
  bne @final_crlf

@done:
  lda #$00
  sta (ptr2),y
  ldax #selector_buffer
  stax url_selector
  clc
  rts

skip_to_hostname:
  ldax url_string
  jsr parser_init
  ldax #colon_slash_slash
  jmp parser_skip_next


.rodata

get:
  .byte "GET "
  get_length = 4

http_preamble:
  .byte " HTTP/1.0",$0d,$0a
  .byte "User-Agent: IP65/0.6502",$0d,$0a
  .byte "Connection: close",$0d,$0a
  .byte "Host: ",0

colon_slash_slash:
  .byte ":/"
slash:
  .byte "/"
zero:
  .byte 0

colon:
  .byte ":",0



; -- LICENSE FOR url.s --
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
