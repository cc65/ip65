.include "../inc/common.inc"

.export _abort_key

.import abort_key
.importzp abort_key_default
.importzp abort_key_disable

_abort_key:
  lsr
  lda #abort_key_default
  bcs :+
  lda #abort_key_disable
: sta abort_key
  rts
