;A2 telnet
;july 2009 (at Mt Keira Fest!) - jonno @ jamtronix.com

  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  .include "../inc/a2keycodes.i" 
 
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__
  .import  __DATA_SIZE__

  .import get_key
  .import cls

.import telnet_connect
.import telnet_local_echo
.import telnet_line_mode
.import telnet_use_native_charset
.import telnet_port
.import telnet_ip
.import cfg_init

  .segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-3                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; Size
        jmp init


.code

init:
  
  jsr cls
  jsr $c300
  ldax #title
  jsr print
  jsr print_cr
  jsr cfg_init  
;  jsr print_ip_config
;  jsr get_key
  init_ip_via_dhcp 
  jsr print_ip_config

@loop_forever:
  ldx #3
@copy_telnet_ip_loop:
  lda remote_host,x
  sta telnet_ip,x
  dex
  bpl @copy_telnet_ip_loop

  ldax #23
  stax telnet_port

  lda #0
  sta telnet_use_native_charset
  sta telnet_line_mode
  lda #1
  sta telnet_local_echo

  jsr telnet_connect
  jmp @loop_forever


exit_telnet:
  rts
  
.rodata
title: .byte "                 TELNET ][",13,"           jonno@jamtronix.com",13,0

resolving:
.byte "RESOLVING ",0

remote_host:
.byte 10,5,2,1
padding: .byte 0,0,0,0,0