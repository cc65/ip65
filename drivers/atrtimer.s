; timer routines
;
; the timer should be a 16-bit counter that's incremented by about
; 1000 units per second. it doesn't have to be particularly accurate.
; this Atari implementation requires the routine timer_vbl_handler be called 60 times per second

.include "../inc/common.i"

.export timer_init
.export timer_exit
.export timer_read
.export timer_seconds


.bss

current_time_value: .res 2
current_seconds:    .res 1
current_jiffies:    .res 1


.data

vbichain: .word 0


.code

; reset timer to 0
; inputs: none
; outputs: none
timer_init:
  lda vbichain+1
  bne @handler_installed
  ldax $222                     ; IMMEDIATE VERTICAL BLANK NMI VECTOR
  stax vbichain                 ; save old immediate vector
  ldy #<timer_vbl_handler
  ldx #>timer_vbl_handler
  lda #6                        ; STAGE 1 VBI
  jsr $e45c                     ; vector to set VBLANK parameters
@handler_installed:
  lda #0
  sta current_time_value
  sta current_time_value+1
  sta current_seconds
  sta current_jiffies
  rts

timer_exit:
  lda vbichain+1
  beq @handler_not_installed
  ldy vbichain
  ldx vbichain+1
  lda #6                        ; STAGE 1 VBI
  jsr $e45c                     ; vector to set VBLANK parameters
@handler_not_installed:
  rts

; read the current timer value
; inputs: none
; outputs: AX = current timer value (roughly equal to number of milliseconds since the last call to 'timer_init')
timer_read:
  ldax current_time_value
  rts

; tick over the current timer value - should be called 60 times per second
; inputs: none
; outputs: none (all registers preserved, but carry flag can be modified)
timer_vbl_handler:
  pha
  lda #17                       ; 60 HZ =~ 17 ms per 'tick'
  clc
  adc current_time_value
  sta current_time_value
  bcc :+
  inc current_time_value+1
: inc current_jiffies
  lda current_jiffies
  cmp #60
  bne @done
  lda #0
  sta current_jiffies
  inc current_seconds
  ; we don't want to mess around with decimal mode in an IRQ handler
  lda current_seconds
  cmp #$0a
  bne :+
  lda #$10
: cmp #$1a
  bne :+
  lda #$20
: cmp #$2a
  bne :+
  lda #$30
: cmp #$3a
  bne :+
  lda #$40
: cmp #$4a
  bne :+
  lda #$50
: cmp #$5a
  bne :+
  lda #$00
: sta current_seconds
@done:
  pla
  jmp $e45f                     ; vector to process immediate VBLANK

timer_seconds:
  lda current_seconds
  rts



;-- LICENSE FOR atrtimer.s --
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
