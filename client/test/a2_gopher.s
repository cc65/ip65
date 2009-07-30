;C64 gopher browser
;july 2009 - jonno @ jamtronix.com

  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  .include "../inc/c64keycodes.i"
  .include "../inc/gopher.i"
  
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__
  .import  __DATA_SIZE__

  .import get_key

  .segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-3                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; Size
        jmp init


.code

init:
  
  jsr cls
  ldax #title
  jsr print
  jsr print_cr
  init_ip_via_dhcp 
  jsr print_ip_config

@loop_forever:
  jsr prompt_for_gopher_resource ;only returns if no server was entered.
  jsr print_cr
  jmp @loop_forever
  
exit_gopher:
  rts
  
.rodata
title:
.byte "                 GOPHER ][",13,"           jonno@jamtronix.com",13,0

resolving:
.byte "RESOLVING ",0
