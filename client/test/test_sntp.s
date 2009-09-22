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

.segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-$11                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; Size
        jmp init

.code

init:

  jsr test_vlb
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


.bss
vla: .res 4
vlb: .res 4
quotient: .res 4
remainder: .res 4

.code
div_32_32:
  lda #0
  sta remainder
  sta remainder+1
  sta remainder+2
  sta remainder+3
  ldx #32
@loop:
  asl vla
  rol vla+1
  rol vla+2
  rol vla+3

  rol remainder
  rol remainder+1
  rol remainder+2
  rol remainder+3 
  
  sec
  lda remainder+0
  sbc vlb+0
  sta remainder+0

  lda remainder+1
  sbc vlb+1
  sta remainder+1

  lda remainder+2
  sbc vlb+2
  sta remainder+2

  lda remainder+3
  sbc vlb+3
  sta remainder+3

  bcs @next
  lda remainder
  adc vlb
  sta remainder

  lda remainder+1
  adc vlb+1
  sta remainder+1

  lda remainder+2
  adc vlb+2
  sta remainder+2

  lda remainder+3
  adc vlb+3
  sta remainder+3
@next:
  rol quotient
  rol quotient+1
  rol quotient+2
  rol quotient+3
  dex
  bpl @loop
  rts
	.rodata

test_vlb:
  ldx #7
: 
  lda divs,x
  sta vla,x
  dex
  bpl :-
  
  jsr div_32_32
  .byte $92
  
  


time_server_msg:
  .byte "TIME SERVER : ",0

time_server_host:
  .byte "202.174.101.10",0
  .byte "1.AU.POOL.SNTP.ORG",0
  
sending_query:
  .byte "SENDING SNTP QUERY TO ",0 
sntp_error:
  .byte "ERROR DURING SNTP QUERY",13,0
  
dns_error:
  .byte "ERROR RESOLVING HOSTNAME",13,0
  
 divs:
  .byte $02,$30,$00,$00
  .byte $05,$00,$00,$00
  
  