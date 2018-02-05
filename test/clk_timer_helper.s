; helper object file to export clr_timer ASM symbols to C

.import timer_init, timer_seconds
.export _timer_init, _timer_seconds

_timer_init = timer_init
_timer_seconds = timer_seconds

.end
