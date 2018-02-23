.include "../inc/common.inc"

.export _http_get_value

.import http_get_value

_http_get_value:
  jsr http_get_value
  bcc :+
  ldx #$00
  txa
: rts
