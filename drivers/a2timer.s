; timer routines
;
; unfortunately the standard Apple 2 has no CIA or VBI, so for the moment, we will
; make each call to 'timer_read' delay for a little while
; this kludge will make the polling loops work at least
; 
; timer_read is meant to return a counter with millisecond resolution

	.include "../inc/common.i"


	.export timer_init
	.export timer_read

  .bss
  current_time_value: .res 2
  
	.code

timer_init:
  ldax  #0
  stax current_time_value
	rts


; return the current value (actually, delay a while, then update current value, then return it in ax)

timer_read:
  lda #111
  jsr $fca8 ;wait for about 33ms
  clc
  lda #33
  adc current_time_value
  sta current_time_value
  bcc :+
  inc current_time_value+1
:
  ldax  current_time_value
  rts

