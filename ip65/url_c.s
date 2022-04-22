.include "../inc/common.inc"

.export _url_parse
.export _url_host
.export _url_ip
.export _url_port
.export _url_selector

.import url_parse
.import url_host
.import url_ip
.import url_port
.import url_selector

.import popax
.importzp tmp1

_url_parse:
  sta tmp1
  jsr popax
  ldy tmp1
  jsr url_parse
  ldx #$00
  txa
  rol
  rts

_url_host := url_host

_url_ip := url_ip

_url_port := url_port

_url_selector := url_selector
