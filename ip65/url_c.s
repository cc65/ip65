.include "../inc/common.inc"

.export _url_parse
.export _url_ip
.export _url_port
.export _url_selector

.import url_parse
.import url_ip
.import url_port
.import url_selector

_url_parse:
  jsr url_parse
  ldx #$00
  txa
  rol
  rts

_url_ip := url_ip

_url_port := url_port

_url_selector := url_selector
