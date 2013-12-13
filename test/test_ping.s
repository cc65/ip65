  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  
  .import exit_to_basic  
  
  .import cfg_get_configuration_ptr
	.import copymem
	.importzp copy_src
	.importzp copy_dest
  
  .import icmp_echo_ip
  .import icmp_ping
  
  
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

.code

init:
  jsr print_cr
  init_ip_via_dhcp 
  jsr print_ip_config
  jsr print_cr
  
  ;our default gateway is probably a safe thing to ping
  ldx #$3
:
  lda cfg_gateway,x
  sta icmp_echo_ip,x
  dex
  bpl :-  
  ldax #pinging
  jsr print
  
  ldax #icmp_echo_ip
  jsr print_dotted_quad
  jsr print_cr
  jsr icmp_ping
  bcs @error
  jsr print_integer
  ldax #ms
  jsr print
  rts
@error:
  jmp print_errorcode
  
.rodata
ms: .byte " MS",13,0
pinging: .byte "PINGING ",0
.bss
block_number: .res 1
block_length: .res 2
buffer1: .res 256
buffer2: .res 256


;-- LICENSE FOR test_ping.s --
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
