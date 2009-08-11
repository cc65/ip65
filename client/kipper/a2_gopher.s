;Apple 2 gopher browser
;july 2009 - jonno @ jamtronix.com

  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  .include "../inc/a2keycodes.i"
;  .include "../inc/c64keycodes.i"


  
  KEY_NEXT_PAGE=$8E ; ^N
  KEY_PREV_PAGE=$90; ^P
  KEY_SHOW_HISTORY=$93; ^S
  KEY_BACK_IN_HISTORY=$82 ; ^B
  KEY_NEW_SERVER=$89 ;TAB key
  
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
  jsr $c300 ; go to 80 column mode


  ldax #title
  jsr print
  jsr print_cr
  init_ip_via_dhcp 
  jsr print_ip_config
  
  
  ldax #initial_location
  sta resource_pointer_lo
  stx resource_pointer_hi
  ldx #0
  jsr  select_resource_from_current_directory
  
exit_gopher:
  jmp $e000
;  rts
  
.rodata
title:
.byte "                 GOPHER ][",13,"           jonno@jamtronix.com",13,0

resolving:
.byte "RESOLVING ",0

initial_location:
.byte "1gopher.floodgap.com",$09,"/",$09,"gopher.floodgap.com",$09,"70",$0D,$0A,0

