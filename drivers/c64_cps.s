; implementation of __clocks_per_sec for C64
; CC65's C64 runtime library doesn't provide this function
; this file provides a version in order that clk_timer.s works without 'ifdefs'

.export __clocks_per_sec

.code

__clocks_per_sec:
  lda #60
  rts

.end
