.include "../inc/common.inc"

.export _input_check_for_abort_key
.export _input_set_abort_key
.export _abort_key

.import check_for_abort_key
.import abort_key
.importzp abort_key_default
.importzp abort_key_disable

_input_check_for_abort_key:
  jsr check_for_abort_key
  ldx #$00
  txa
  rol
  rts

_input_set_abort_key:
  lsr
  lda #abort_key_default
  bcs :+
  lda #abort_key_disable
: sta abort_key
  rts

_abort_key := abort_key
