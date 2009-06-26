  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  
  .import exit_to_basic  
  
  .import parse_dotted_quad
  .import dotted_quad_value
  
  .import tcp_listen
  .import tcp_callback
  .import ip65_process
  .import tcp_connect
  .import tcp_remote_ip
  
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__
  .import  __DATA_SIZE__
  

  .importzp acc32
  .importzp op32

  .import add_32_32
  .import add_16_32
  
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

.code

init:
    
  jsr print_cr
 
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

    
  jsr print_cr
  init_ip_via_dhcp 
  jsr print_ip_config

@loop_forever:
  ldax  #tcp_callback_routine
  stax  tcp_callback
  ldax  tcp_dest_ip
  stax  tcp_remote_ip
  ldax  tcp_dest_ip+2
  stax  tcp_remote_ip+2
  
  
  ldax  #80
  jsr tcp_connect

  jsr ip65_process
  jmp @loop_forever
  rts

tcp_callback_routine:
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

tcp_dest_ip:
  .byte 10,5,1,1