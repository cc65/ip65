.include "../inc/common.i"
.include "../inc/commonprint.i"
.include "../inc/net.i"

.export start

.import exit_to_basic

.import httpd_start
.import http_get_value


; keep LD65 happy
.segment "ZPSAVE"


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
  lda #'h'
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
  .byte ":",0
html:
  .byte "<h1>hello world</h1>%?mMessage recorded as '%$h:%$m'%.<form>Your Handle:<input name=h type=text length=20 value='%$h'><br>Your Message: <input type=text lengh=60 name='m'><br><input type=submit></form><br>",0



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
