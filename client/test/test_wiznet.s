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
  .import w5100_read_register
  .import w5100_write_register
  .import w5100_select_register
  .import w5100_get_current_register
  .import w5100_read_next_byte
  .import w5100_write_next_byte
  
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
; jsr wait_for_keypress
  init_ip_via_dhcp
; jsr wait_for_keypress

  jsr print_ip_config
;
;  jsr wait_for_keypress
;  jsr dhcp_init
  rts
;  jsr print_ip_config
 print_driver_init
  jsr ip65_init
  jsr print_cr

;  jsr	wiznet_dump

;  ldax #W5100_S0_RX_RSR0
;  jsr dump_current_register
;  jsr	wait_for_keypress
;  jsr dump_current_register
  
   ldax #sending
   jsr	print
   jsr	wait_for_keypress
   jsr send_frame
   jsr	wiznet_dump
   jsr dump_current_register
   
   
@wait_for_frame: 	
  	ldax #W5100_S0_RX_RSR0
	jsr  w5100_read_register
  	bne	:+
	jsr  w5100_read_next_byte
  	bne	:+
  	inc	$d020
;  	jsr dump_current_register
;	jsr	wiznet_dump

  	jmp @wait_for_frame
:

 	jsr dump_frame
 	

  
  ldx #$0
:
  lda ping_dest,x
  lda	#5
  jsr	w5100_write_next_byte
  inx
  inc	$d021
  cpx	#$4
  bne :-

  jsr	dump_current_register

  jsr	wiznet_dump
  
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

dump_current_register:
  jsr w5100_get_current_register
print_ax_hex:  
  pha
  txa
  jsr	print_hex
  pla	
  jmp	print_hex

send_frame:
 
  ldax #test_frame_length
  stax tx_length

  lda #0
  sta byte_count
  sta byte_count+1
  
  ldax #$4000
  stax tx_ptr
 
@write_one_byte:	
  ldy	tx_ptr
  lda	test_frame,y
  tay
  ldax	tx_ptr  
  
  jsr  w5100_write_register
    
  inc	byte_count
  bne	:+
  inc	byte_count+1
 :
 
  inc	tx_ptr
  bne	:+
  inc	tx_ptr+1
 :
 
 lda	byte_count
 cmp	tx_length
 bne	@write_one_byte
 
 tay
 ldax 	#W5100_S0_TX_WR1  
 jsr  	w5100_write_register

 ldax 	#W5100_S0_CR
 ldy	#W5100_CMD_SEND_MAC
 jsr	w5100_write_register

  lda #$40
  sta register_page
  jsr dump_wiznet_register_page

 jmp	wait_for_keypress




dump_frame:
  jsr	print_cr
  jsr	wiznet_dump
 
  ldax #W5100_S0_RX_RSR0
  jsr  w5100_read_register
  sta rx_length+1  
  jsr  w5100_read_next_byte
  sta rx_length
  ldx	rx_length+1  
  jsr	print_ax_hex
  
 ; jsr	wait_for_keypress

  jsr print_cr

  lda #0
  sta byte_count
  sta byte_count+1
  
  ldax #$6000
  stax rx_ptr
 
@read_one_byte:
  ldax	rx_ptr  
  jsr  w5100_read_register
  jsr print_hex
    
  inc	byte_count
  bne	:+
  inc	byte_count+1
 :
 
  inc	rx_ptr
  bne	:+
  inc	rx_ptr+1
 :
 
 lda	byte_count
 cmp	rx_length
 bne	@read_one_byte
 lda	byte_count+1
 cmp	#4
 beq	@done
 cmp	rx_length+1
 bne	@read_one_byte
 
 @done:

 
 jsr	print_cr
 jsr	dump_current_register
 jsr	print_cr
 ldax	rx_length
 jsr print_hex
 
 jmp	wait_for_keypress

wiznet_dump:
 lda #0
  sta register_page
  jsr dump_wiznet_register_page
  lda #$4
  sta register_page
  jsr dump_wiznet_register_page
    
  jsr	wait_for_keypress
  
  jmp	print_cr
 
dump_wiznet_register_page:
  sta register_page
  lda #0
  sta current_register
   jsr print_cr

@one_row:
  lda current_register
  cmp #$40
  beq @done
  lda register_page
  jsr print_hex
  lda current_register  
  jsr print_hex
  lda #':'
  jsr print_a
  lda #' '
  jsr print_a

  lda #0
  sta current_byte_in_row
  
@dump_byte:
  lda current_register
  ldx register_page
  jsr w5100_read_register
  jsr print_hex
  lda #' '
  jsr print_a
  inc current_register
  inc current_byte_in_row
  lda current_byte_in_row
  cmp #08
  bne @dump_byte
  
 jsr print_cr
  jmp @one_row
@done:
  jsr print_cr
  rts

wait_for_keypress:
  lda #0
  sta $c6 ;set the keyboard buffer to be empty
  ldax  #press_a_key_to_continue
  jsr print
  jsr get_key  
  rts
  
.rodata
ms: .byte " MS",13,0
pinging: .byte "PINGING ",13,10,0
sending: .byte "SENDING ",13,10,0
hello: .byte "HELLO WORLD!",13,10,0
sock_0:	.byte "SOCKET 0 ",0
read:	.byte "READ",0
write_addr: .byte "WRITE"
addr: .byte " ADDRESS : ",0

ping_dest: .byte 10,5,1,1


test_frame:
.byte $ff,$ff,$ff,$ff,$ff,$ff
.byte $01,$02,$03,$04,$05,$06,$07,$08
.byte $11,$12,$13,$14,$15,$16,$17,$18
.byte $21,$22,$23,$24,$25,$26,$27,$28
.byte $31,$32,$33,$34,$35,$36,$37,$38
.byte $ff,$ff,$ff,$ff,$ff,$ff
.byte $ff,$ff,$ff,$ff,$ff,$ff
.byte $01,$02,$03,$04,$05,$06,$07,$08
.byte $11,$12,$13,$14,$15,$16,$17,$18
.byte $21,$22,$23,$24,$25,$26,$27,$28
.byte $31,$32,$33,$34,$35,$36,$37,$38

test_frame_length=*-test_frame
.bss
rx_length: .res 2
rx_ptr:	.res 2
byte_count:	.res 2

tx_length: .res 2
tx_ptr:	.res 2

current_register:.res 1
current_byte_in_row: .res 1
register_page: .res 1



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
