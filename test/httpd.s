.include "../inc/common.inc"
.include "../inc/commonprint.inc"
.include "../inc/net.inc"

.define HTML "<h1>Hello World</h1><form>Your Name: <input name=n type=text length=20><br>Your Message: <input name=m type=text lengh=60><br><input type=submit></form>"

.export start

.import exit_to_basic

.import httpd_start
.import httpd_response_buffer_length
.import http_get_value


; keep LD65 happy
.segment "INIT"
.segment "ONCE"


.segment "STARTUP"

  lda #14
  jsr print_a                   ; switch to lower case

start:
  ldax #initializing
  jsr print
  init_ip_via_dhcp
  bcs :+
  jsr print_ip_config

  ldax #listening
  jsr print
  ldax #httpd_callback
  jsr httpd_start

: jmp exit_to_basic

print_vars:
  lda #'n'
  jsr http_get_value
  bcs :+
  jsr print
  ldax #said
  jsr print
  lda #'m'
  jsr http_get_value
  bcs :+
  jsr print
  jsr print_cr
: rts

httpd_callback:
  jsr print_vars
  lda #<.strlen(HTML)
  ldx #>.strlen(HTML)
  stax httpd_response_buffer_length
  ldax #html
  ldy #2                        ; text/html
  clc
  rts


.rodata

initializing:
  .byte 13,"INITIALIZING",13,0
listening:
  .byte "LISTENING",13,0
said:
  .byte " said ",0
html:
  .byte HTML



; -- LICENSE FOR httpd.s --
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
