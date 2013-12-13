  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  
  .import exit_to_basic  
  .import cfg_get_configuration_ptr
  .import dns_set_hostname
  .import dns_resolve
  .import dns_ip
  .import dns_status
  .import sntp_ip
  .import sntp_utc_timestamp
  .import sntp_get_time
  
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

init:
  lda #14
  jsr print_a ;switch to lower case 
  jsr print_cr
  init_ip_via_dhcp 
  jsr print_ip_config
  
  ldax #time_server_msg
  jsr print 
  ldax #time_server_host  
  jsr print 
  jsr print_cr
  ldax #time_server_host  
  jsr dns_set_hostname
  bcs @dns_error
  jsr dns_resolve
  bcs @dns_error
  ldx #3				; set destination address
: lda dns_ip,x
	sta sntp_ip,x
	dex
	bpl :-
  
  
  ldax #sending_query
  jsr print
  ldax #sntp_ip
  jsr print_dotted_quad
  jsr print_cr
  jsr sntp_get_time
  bcc @ok
  ldax #sntp_error
  jmp @print_error
@ok:
  ldy #3
:  
  lda sntp_utc_timestamp,y
  jsr print_hex
  dey
  bpl :-
  jmp exit_to_basic

@dns_error:  
  ldax #dns_error
@print_error:  
  jsr print
  jsr print_errorcode
  jmp exit_to_basic


.data  
  


time_server_msg:
  .byte "TIME SERVER : ",0

time_server_host:
  .byte "jamtronix.com",0
;  .byte "150.101.112.134",0
  .byte "0.POOL.SNTP.ORG",0
  
sending_query:
  .byte "SENDING SNTP QUERY TO ",0 
sntp_error:
  .byte "ERROR DURING SNTP QUERY",13,0
  
dns_error:
  .byte "ERROR RESOLVING HOSTNAME",13,0
  
 divs:
  .byte $02,$30,$00,$00
  .byte $05,$00,$00,$00
  
  


;-- LICENSE FOR test_sntp.s --
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
