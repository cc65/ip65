; timer routines
; this implementation is for Atari and C64.
; it uses parts of the C runtime library
;
; the timer should be a 16-bit counter that's incremented by about
; 1000 units per second. it doesn't have to be particularly accurate.

.include "../inc/common.i"

.export timer_init
.export timer_read
.export timer_seconds

.import   __clocks_per_sec, _clock
.import   tosumodeax, tosudiveax
.import   pusheax, incsp4
.importzp sp, sreg


.bss

timer_freq: .res 1      ; VBLANK frequency: 50 - PAL, 60 - NTSC (Atari); always 60 (C64)
mult_temp:  .res 2      ; temp var for multiplication routines        
mult_temp_x:.res 1      ; another temp var for multiplication routines        


.data

mult: .byte $4C  ; JMP opcode
      .res 2     ; address


.code

; get timer frequency and patch multiplication routine pointer
; inputs: none
; outputs: none
timer_init:
  jsr __clocks_per_sec
  sta timer_freq
  cmp #50
  beq @timer50
  lda #<mult17
  ldx #>mult17
  bne @timerset                 ; jmp always
@timer50:
  lda #<mult20
  ldx #>mult20
@timerset:
  sta mult+1
  stx mult+2
  rts

; read the current timer value
; inputs: none
; outputs: AX = current timer value in milliseconds
timer_read      =       mult

; get current seconds clock hand
; inputs: none
; outputs: A = seconds hand (in BCD, range $00..$59)
timer_seconds:
  jsr _clock                    ; return current tick count in sreg:AX (high:low 16bits)
  jsr pusheax                   ; push tick count onto stack
  ldx #0
  stx sreg
  stx sreg+1
  lda timer_freq
  jsr tosudiveax                ; dividend on stack, divisor in sreg:AX
  jsr pusheax
  ldx #0
  stx sreg
  stx sreg+1
  lda #60
  jsr tosumodeax                ; result modulo 60
  ; convert to BCD, a poor man's conversion here....
  cmp #50
  bcs @rs_50
  cmp #40
  bcs @rs_40
  cmp #30
  bcs @rs_30
  cmp #20
  bcs @rs_20
  cmp #10
  bcs @rs_10
  rts
@rs_10:
  sbc #10
  ora #$10
  rts
@rs_20:
  sbc #20
  ora #$20
  rts
@rs_30:
  sbc #30
  ora #$30
  rts
@rs_40:
  sbc #40
  ora #$40
  rts
@rs_50:
  sbc #50
  ora #$50
  rts


; get the current tick count, multiply it by 20, and return the lower 16 bits
; x*20 = x*16 + x*4
; inputs: none
; outputs: AX - tick count times 20 ('milliseconds')
mult20:
  jsr _clock                    ; return current tick count in sreg:AX (high:low 16bits)
  stx mult_temp_x               ; remember high byte of lower 16bits
  asl a
  rol mult_temp_x
  asl a
  rol mult_temp_x
  sta mult_temp
  ldx mult_temp_x
  stx mult_temp+1               ; mult_temp = ticks * 4
  asl a
  rol mult_temp_x
  asl a
  rol mult_temp_x               ; mult_temp_x:A = 'ticks * 16'
  clc                           ; AX - tick count * 16, mult_temp - tick count * 4
  adc mult_temp
  sta mult_temp
  lda mult_temp+1
  adc mult_temp_x
  tax
  lda mult_temp
  rts


; get the current tick count, multiply it by 17, and return the lower 16 bits
; x*17 = x*16 + x
; inputs: none
; outputs: AX - tick count times 17 ('milliseconds')
mult17:
  jsr _clock                    ; return current tick count in sreg:AX (high:low 16bits)
  sta mult_temp
  stx mult_temp+1
  stx mult_temp_x
  .repeat 4
  asl a
  rol mult_temp_x
  .endrepeat                    ; mult_temp_x:A = 'ticks * 16'
  clc
  adc mult_temp
  sta mult_temp
  lda mult_temp+1
  adc mult_temp_x
  tax
  lda mult_temp
  rts


;-- LICENSE FOR clk_timer.s --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
; 
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
; -- LICENSE END --
