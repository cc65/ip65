  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  .include "../drivers/w5100.i"

  .import exit_to_basic  
  
  .import cfg_get_configuration_ptr
  .import copymem
  .importzp copy_src
  .importzp copy_dest
  .import icmp_echo_ip
  .import icmp_ping
  .import get_key
  .import w5100_ip65_init
  
  .import dns_set_hostname
  .import dns_resolve
  .import dns_ip
  .import dns_status

  
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

; jsr wait_for_keypress
	ldax #$DE00
	jsr	probe_for_w5100
	bcc	@found
	ldax #$DF00
	jsr	probe_for_w5100
	bcc	@found	
	ldax #$DF20
	jsr	probe_for_w5100
	bcc	@found
	ldax	#no_wiznet
	jmp	print
	rts
	
@found:
  jsr dhcp_init

@skip:


  jsr print_ip_config
;   jsr wait_for_keypress
;
;  rts
;
;  jsr wait_for_keypress
;  jsr dhcp_init
;  jsr print_ip_config
; print_driver_init
;  jsr ip65_init
;  jsr print_cr

	jsr	ping_test
	jsr	ping_test_2

	ldax #hostname_1
	jsr do_dns_query  
	bcs	:+
	jsr	ping_test_3
:
	rts
	

ping_test:
  ldx #$3
:
  lda dhcp_server,x
  sta icmp_echo_ip,x
  dex
  bpl :-  
  jmp	do_ping	 
  
ping_test_2:
  ldx #$3
:
  lda cfg_gateway,x
  sta icmp_echo_ip,x
  dex
  bpl :-  
  jmp	do_ping	 

ping_test_3:
  ldx #$3
:
  lda dns_ip,x
  sta icmp_echo_ip,x
  dex
  bpl :-  
  jmp	do_ping	 
  
 
do_ping: 
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

 rts


probe_for_w5100:
  stax w5100_addr
  ldax	#probing
  jsr	print
  lda	w5100_addr+1
  jsr	print_hex
  lda	w5100_addr
  jsr	print_hex
  jsr	print_cr
  ldax w5100_addr
  jmp	w5100_ip65_init

wait_for_keypress:
  lda #0
  sta $c6 ;set the keyboard buffer to be empty
  ldax  #press_a_key_to_continue
  jsr print
  jsr get_key  
  rts



do_dns_query:
  pha
  jsr print
  lda #' '
  jsr print_a
  lda #':'
  jsr print_a
  lda #' '
  jsr print_a
  pla
  jsr dns_set_hostname
  jsr dns_resolve
  bcc :+
  ldax #dns_lookup_failed_msg
  jsr print
  sec
  rts
:  
  ldax #dns_ip
  jsr print_dotted_quad
  jsr	print_cr
  clc
  rts

  
.rodata
ms: .byte " MS",13,0
pinging: .byte "PINGING ",0
hello: .byte "HELLO WORLD!",13,10,0
no_wiznet: .byte "NO W5100 FOUND",13,10,0
probing: .byte "LOOKING FOR W5100 AT $",0
ping_ip: .byte 10,5,1,84
hostname_1: .byte "JAMTRONIX.COM",0     
.bss
w5100_addr: .res 2


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
