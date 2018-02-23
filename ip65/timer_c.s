.include "../inc/common.inc"

.export _timer_read
.export _timer_timeout

.import timer_read
.import timer_timeout

_timer_read := timer_read

_timer_timeout:
  jsr timer_timeout
  ldx #$00
  txa
  rol
  eor #$01
  rts
