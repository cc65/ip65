.include "../inc/common.i"
.include "../inc/commonprint.i"
.include "../inc/net.i"

.export start

.import exit_to_basic

.import print_a
.import get_key
.import ascii_to_native
.import parser_init
.import parser_skip_next
.importzp copy_src
.importzp copy_dest
.import url_ip
.import url_port
.import url_selector
.import url_resource_type
.import url_parse
.import url_download
.import url_download_buffer
.import url_download_buffer_length

temp_buff = copy_dest


; keep LD65 happy
.segment "ZPSAVE"


.segment "STARTUP"

  ; switch to lower case charset
  lda #14
  jsr print_a

start:
  jsr print_cr
  init_ip_via_dhcp
  jsr print_ip_config

  ldax #url_1
  jsr test_url_download

  ldax #url_2
; jsr test_url_download

  jmp exit_to_basic

test_url_download:
  stax temp_url_ptr
  ldax #downloading
  jsr print
  ldax temp_url_ptr
  jsr print
  jsr print_cr
  ldax #dl_buffer
  stax url_download_buffer
  ldax #dl_buffer_length
  stax url_download_buffer_length

  ldax temp_url_ptr
  jsr url_download
  bcc :+
  jmp print_errorcode
: ldax #dl_buffer
  jsr parser_init
@next_title:
  ldax #title
  jsr parser_skip_next
  bcs @done

  jsr print_tag_contents
  jsr print_cr

  jmp @next_title
@done:
  rts

wait_key:
  ldax #press_a_key
  jsr print
  jmp get_key

print_tag_contents:
  stax temp_buff
  lda #0
  sta string_offset
@next_byte:
  ldy string_offset
  lda (temp_buff),y
  beq @done
  cmp #'<'
  beq @done
  jsr ascii_to_native
  jsr print_a
  inc string_offset
  beq @done
  jmp @next_byte
@done:
  rts


.data

title:
  .byte "<title>",0

url_1:
  .byte "http://static.cricinfo.com/rss/livescores.xml",0
url_2:
  .byte "http://search.twitter.com/search.atom?q=kipper",0

downloading:
  .asciiz "DOWNLOADING "
press_a_key:
  .byte "PRESS ANY KEY TO CONTINUE",13,0


.bss

string_offset: .res 1
selector_ptr:  .res 2
temp_url_ptr:  .res 2

dl_buffer_length = 8092
dl_buffer: .res dl_buffer_length



; -- LICENSE FOR geturl.s --
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
