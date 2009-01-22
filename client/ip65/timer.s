;originally from Per Olofsson's IP65 library - http://www.paradroid.net/ip65

; timer routines
;
; the timer should be a 16-bit counter that's incremented by about
; 1000 units per second. it doesn't have to be particularly accurate,
; if you're working with e.g. a 60 Hz VBLANK IRQ, adding 17 to the
; counter every frame would be just fine.


	.include "../inc/common.i"


	.export timer_timeout
  .import timer_read

	.bss

time:		.res 2


	.code

; check if value in A/X is smaller than current timer value
timer_timeout:
	pha
  txa
  pha
  jsr timer_read
  stax time
  pla
  tax
	pla
	sec			; subtract current value
	sbc time
	txa
	sbc time + 1
	rts			; clc = timeout, sec = no timeout
