; timer routines
;
; the timer should be a 16-bit counter that's incremented by about
; 1000 units per second. it doesn't have to be particularly accurate.

	.include "../inc/common.i"

	.export timer_init
	.export timer_read
  .export timer_seconds  ; this should return a single BCD byte (00..59) which is a count of seconds
	.code
  
; initialize timers
timer_init:
	lda #$80		; stop timers
	sta $dd0e
	sta $dd0f

	ldax #999		; timer A to 1000 cycles
	stax $dd04

	ldax #$ffff		; timer B to max cycles
	stax $dd06

	lda #$81		; timer A in continuous mode
	sta $dd0e

	lda #$c1		; timer B to count timer A underflows
	sta $dd0f

  lda #0
  sta $dc08
  sta $dc09
	rts

timer_seconds:
  lda $dc09
  rts

; return the current value
timer_read:
	lda $dd07		; cia counts backwards, return inverted value
	eor #$ff
	tax
	lda $dd06
	eor #$ff
	rts





;-- LICENSE FOR c64timer.s --
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
