  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  
  .import exit_to_basic  
  .import ascii_to_native  
  .import parse_dotted_quad
  .import dotted_quad_value
  
  .import tcp_listen
  .import tcp_callback
  .import ip65_random_word
  .import ip65_error

  .import tcp_connect
  .import tcp_connect_ip

  .import tcp_inbound_data_ptr
  .import tcp_inbound_data_length

  .import tcp_send
  .import tcp_send_data_len
  
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__
  .import  __DATA_SIZE__
  

  .importzp acc32
  .importzp op32
  .importzp acc16
  
  .import add_32_32
  .import add_16_32
  .import cmp_32_32
  .import cmp_16_16
  .import mul_8_16

  .import sub_16_16

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

.segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-$11                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; Size
        jmp init

.bss 
cxn_closed: .res 1
byte_counter: .res 1

.data
get_next_byte: 
  lda $ffff
  rts

.code

init:
  

  ldax  #$1234
  stax acc16
  ldax  #$1235
  jsr  test_sub_16_16

  ldax  #$180
  stax acc16
  ldax  #$28
  jsr  test_sub_16_16

  rts
  ldax  #$ff34
  stax acc16
  ldax  #$1235
  jsr  test_sub_16_16

  ldax  #$100
  stax acc16
  ldax  #$ffff
  jsr  test_sub_16_16

  ldax  #$ffff
  stax acc16
  ldax  #$100
  jsr  test_sub_16_16
  
  
  ldax  #number1
  stax acc32
  stax op32
  jsr  test_cmp_32_32

  ldax  #number1
  stax acc32
  ldax  #number13
  stax op32
  jsr  test_cmp_32_32

  ldax  #number1
  stax acc32
  ldax  #number2
  stax op32
  jsr  test_cmp_32_32

  ldax  #$12
  stax acc16
  jsr  test_cmp_16_16

  ldax  #$1234
  stax acc16
  jsr  test_cmp_16_16

  ldax  #$1234
  stax acc16
  ldax  #$1235
  jsr  test_cmp_16_16


  ldax  #$1234
  stax acc16
  ldax  #$2234
  jsr  test_cmp_16_16
  

  ldax  #$0000
  stax acc16
  jsr  test_cmp_16_16

  ldax  #$FFFF
  stax acc16
  jsr  test_cmp_16_16



  ldax  #number1
  stax acc32
  ldax  #number2
  stax op32
  jsr test_add_32_32

  
  
  ldax  #number3
  stax acc32
  ldax  #number4
  stax op32
  jsr test_add_32_32

  ldax  #number5
  stax acc32
  ldax  #number6
  stax op32
  jsr test_add_32_32

  ldax  #number7
  stax acc32
  ldax  #number8
  stax op32
  jsr test_add_32_32

  ldax  #number9
  stax acc32
  ldax  #number10
  stax op32
  jsr test_add_32_32

  ldax  #number11
  stax acc32
  ldax  #number12
  stax op32
  jsr test_add_32_32


  ldax  #number13
  stax acc32
  ldax  #$1234
  jsr test_add_16_32

  ldax  #number14
  stax acc32
  ldax  #$1234
  jsr test_add_16_32

  ldax  #number15
  stax acc32
  ldax  #$1234
  jsr test_add_16_32

  ldax  #number16
  stax acc32
  ldax  #$1234
  jsr test_add_16_32

  ldax  #number17
  stax acc32
  ldax  #$158
  jsr test_add_16_32

    
  jsr print_cr
  init_ip_via_dhcp 
  jsr print_ip_config

  jsr print_cr

  
  jsr print_random_number  
 
  ;connect to port 81 - should be rejected

  ldax  #tcp_callback_routine
  stax  tcp_callback
  ldax  tcp_dest_ip
  stax  tcp_connect_ip
  ldax  tcp_dest_ip+2
  stax  tcp_connect_ip+2
    
  ldax  #81
  jsr tcp_connect
  jsr check_for_error

  ldax  #http_get_length
  stax  tcp_send_data_len
  ldax  #http_get_msg
  jsr   tcp_send
  jsr check_for_error
  
  ;now try to connect to port 80 - should be accepted

  ldax  #tcp_callback_routine
  stax  tcp_callback
  ldax  tcp_dest_ip
  stax  tcp_connect_ip
  ldax  tcp_dest_ip+2
  stax  tcp_connect_ip+2  
 
  
  ldax  #80
  jsr tcp_connect
  jsr check_for_error

  lda #0
  sta cxn_closed

  ldax  #http_get_length
  stax  tcp_send_data_len
  ldax  #http_get_msg
  jsr   tcp_send
  jsr check_for_error

@loop_till_end:
  jsr ip65_process
  lda #1
  cmp cxn_closed

  beq @loop_till_end
  
  rts


  ldax  #tcp_callback_routine
  stax  tcp_callback
  ldax  tcp_dest_ip
  stax  tcp_connect_ip
  ldax  tcp_dest_ip+2
  stax  tcp_connect_ip+2  
 


  ldax  #80
  jsr tcp_connect
  jsr check_for_error
  
  ldax  #4
  stax  tcp_send_data_len
  ldax  #http_get_msg
  jsr   tcp_send
  jsr check_for_error
  ldax  #http_get_length-4
  stax  tcp_send_data_len
  ldax  #http_get_msg+4
  jsr   tcp_send
  jsr check_for_error


  ldax  #looping
  jsr print
@loop_forever:
  jsr ip65_process
  jmp @loop_forever  
  rts

tcp_callback_routine:


  
  lda tcp_inbound_data_length
  cmp #$ff
  bne @not_end_of_file
  lda #1
  sta cxn_closed
  rts
  
@not_end_of_file:
  lda #14
  jsr print_a ;switch to lower case

 
  ldax tcp_inbound_data_ptr
  stax get_next_byte+1
    
  lda #0
  sta byte_counter
  sta byte_counter+1
  
@print_one_byte:
  jsr get_next_byte  
  jsr ascii_to_native
  
  jsr print_a
  inc get_next_byte+1
  bne :+
  inc get_next_byte+2
:

  inc byte_counter
  bne :+
  inc byte_counter+1
:
  ldax  byte_counter
  stax  acc16
  ldax tcp_inbound_data_length
  jsr cmp_16_16
  bne @print_one_byte
  
  rts
  


check_for_error:
  lda ip65_error
  beq @exit
  ldax #error_code
  jsr print
  lda ip65_error
  jsr  print_hex
  jsr print_cr
  lda #0
  sta ip65_error
@exit:  
  rts

print_random_number:
  jsr ip65_random_word
  stx  temp_ax
  jsr print_hex
  lda  temp_ax
  jsr print_hex
  jsr print_cr
  rts

;assumes acc32 & op32 already set
test_add_32_32:
  ldy #3  
:
  lda  (acc32),y
  jsr  print_hex
  dey
  bpl :-
  
  lda #'+'
  jsr print_a
  ldy #3  
:
  lda  (op32),y
  jsr  print_hex
  dey
  bpl :-
  
  lda #'='
  jsr print_a
  jsr add_32_32
  
  ldy #3  
:
  lda  (acc32),y
  jsr  print_hex
  dey
  bpl :-
  jsr print_cr
  rts



;assumes acc32 & op32 already set
test_cmp_32_32:
  ldy #3  
:
  lda  (acc32),y
  jsr  print_hex
  dey
  bpl :-
  
  lda #'='
  jsr print_a
  ldy #3  
:
  lda  (op32),y
  jsr  print_hex
  dey
  bpl :-
  
  lda #':'
  jsr print_a
  jsr cmp_32_32
  bne @not_equal
  lda #'T'
  jmp @char_set
@not_equal:
  lda #'F'
@char_set:
  jsr print_a
  jsr print_cr
  rts

;assumes acc16& AX already set
test_cmp_16_16:
  stax  temp_ax
  lda acc16+1
  jsr print_hex
  lda acc16
  jsr print_hex
  
  lda #'='
  jsr print_a
  lda temp_ax+1
  jsr print_hex
  lda temp_ax
  jsr print_hex
    
  lda #':'
  jsr print_a
  ldax  temp_ax
  jsr cmp_16_16
  bne @not_equal
  lda #'T'
  jmp @char_set
@not_equal:
  lda #'F'
@char_set:
  jsr print_a
  jsr print_cr
  rts


;assumes acc32 & AX already set
test_add_16_32:
  stax  temp_ax
  ldy #3  
:
  lda  (acc32),y
  jsr  print_hex
  dey
  bpl :-
  
  lda #'+'
  jsr print_a

  lda temp_ax+1
  jsr print_hex
  lda temp_ax
  jsr print_hex
  
  lda #'='
  jsr print_a
  ldax  temp_ax
  jsr add_16_32
  
  ldy #3  
:
  lda  (acc32),y
  jsr  print_hex
  dey
  bpl :-
  jsr print_cr
  rts

;assumes acc16& A already set
test_mul_8_16:
  sta  temp_ax
  lda acc16+1
  jsr print_hex
  lda acc16
  jsr print_hex
  
  lda #'*'
  jsr print_a
  lda temp_ax
  jsr print_hex
    
  lda #'='
  jsr print_a
  lda  temp_ax
  jsr mul_8_16
  lda acc16+1
  jsr print_hex
  lda acc16
  jsr print_hex
  jsr print_cr
  rts


;assumes acc16 & AX already set
test_sub_16_16:
  stax  temp_ax

  lda acc16+1
  jsr print_hex
  lda acc16
  jsr print_hex

  lda #'-'
  jsr print_a

  lda temp_ax+1
  jsr print_hex
  lda temp_ax
  jsr print_hex
  
  lda #'='
  jsr print_a
  ldax  temp_ax
  jsr sub_16_16
  
  lda acc16+1
  jsr print_hex
  lda acc16
  jsr print_hex

  jsr print_cr
  rts


@error:
  ldax  #failed_msg
  jsr print
  jsr print_cr
  rts
  
  .bss
  temp_ax: .res 2
  
	.rodata


.data
number1:
  .byte $1,$2,$3,$f
number2:
.byte $10,$20,$30,$f0
number3:
  .byte $ff,$ff,$ff,$ff  
number4:
  .byte $1,$0,$0,$0
  
number5:
  .byte $ff,$ff,$ff,$ff  
number6:
  .byte $0,$0,$0,$0
number7:
  .byte $ff,$ff,$ff,$fe  
number8:
  .byte $1,$0,$0,$0
number9:
  .byte $ff,$ff,$ff,$fe  
number10:
  .byte $5,$0,$0,$0
number11:
  .byte $ff,$0,$0,$e
number12:
  .byte $5,$0,$0,$0
    
number13:
  .byte $1,$2,$3,$4
  
number14:
  .byte $ff,$ff,$ff,$ff

number15:
  .byte $ff,$ff,$00,$00

number16:
  .byte $00,$00,$00,$00

number17:
  .byte $5b,$bc,$08,$a9

tcp_dest_ip:
 ; .byte 10,5,1,1
  .byte 74,207,242,229
looping:
  .asciiz "LOOPING..."
  
http_get_msg:
  .byte "GET /blogx/ HTTP/1.0",13,10,13,10
http_get_msg_end:  
 http_get_length=http_get_msg_end-http_get_msg
 
 


;-- LICENSE FOR test_tcp.s --
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
