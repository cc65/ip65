.include "../inc/common.i"
.include "../inc/commonprint.i"
.include "../inc/net.i"

.import print_a
.import get_key
.import cfg_get_configuration_ptr
.import ascii_to_native

.import http_parse_request
.import http_get_value


.bss
temp_ax: .res 2
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

init:

  ;switch to lower case charset
  lda #23
  sta $d018


  ldax #query_1
  jsr test_querystring
  ldax #query_2
  jsr test_querystring  
  ldax #query_3
  jsr test_querystring
  jsr get_key
  ldax #query_4
  jsr test_querystring
  ldax #query_5
  jsr test_querystring  
  ldax #query_6
  jsr test_querystring  

  rts

test_querystring:
  stax  temp_ax
  jsr print_ascii_as_native
  jsr print_cr
  ldax  temp_ax
  jsr http_parse_request
  
  lda #1
  jsr print_var
  lda #2
  jsr print_var
  lda #'h'
  jsr print_var
  lda #'m'
  jsr print_var
  lda #'q'
  jsr print_var  
  rts

print_var:
  pha
  cmp #1
  beq @print_method
  cmp #2  
  beq @print_path
  jsr ascii_to_native

  jsr print_a
@print_equals:
  lda #'='
  jsr print_a
  pla
  jsr http_get_value
  bcc @found_var_value
  lda #'?'
  jsr print_a
  jmp print_cr
@found_var_value:  
  jsr print_ascii_as_native
  jmp print_cr
  
@print_path:
  ldax #path
  jmp @print_caption
@print_method:
  ldax #method
@print_caption:
  jsr print_ascii_as_native
  jmp @print_equals

.rodata
path: .byte "path",0
method: .byte "method",0

query_1: 
.byte "GET /?h=slack&m=goober+woober+woo%21+%3B+i+am+text HTTP/1.1",0
query_2: 
.byte "POST /?h=slack&m=goober+woober+woo!+%3b+i+am+text",0
query_3: 
.byte "GET /?handle=slack&message=goober+woober+woo%21+%3B+i+am+text+%0d%0a%21%40%23%24%25%5E%26%25%5D%5B%7B%7D& HTTP/1.1",0
query_4: 
.byte "GET /this/is/a/long/q/path.html?q=foo",0
query_5: 
.byte "/this/is/a/gopher_selector",0
query_6: 
.byte $0d,$0a,0  ;this should also be a gopher path




;-- LICENSE FOR test_parse_querystring.s --
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
