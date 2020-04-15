.include "../inc/common.inc"

.export _ip65_init
.export _ip65_process
.export _ip65_random_word
.export _ip65_error
.export _ip65_strerror

.import ip65_init
.import ip65_process
.import ip65_random_word
.import ip65_error
.import ip65_strerror

_ip65_init:
  jsr ip65_init
  ldx #$00
  txa
  rol
  rts

_ip65_process:
  jsr ip65_process
  ldx #$00
  txa
  rol
  rts

_ip65_random_word := ip65_random_word

_ip65_error := ip65_error

_ip65_strerror := ip65_strerror
