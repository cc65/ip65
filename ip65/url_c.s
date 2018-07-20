.include "../inc/common.inc"

.export _url_parse
.export _url_download
.export _url_ip
.export _url_port
.export _url_selector

.import url_parse
.import url_download
.import url_download_buffer
.import url_download_buffer_length
.import url_ip
.import url_port
.import url_selector
.import resource_buffer

.import popax

_url_parse:
  jsr url_parse
  ldx #$00
  txa
  rol
  rts

_url_download:
  stax url_download_buffer_length
  jsr popax
  stax url_download_buffer
  jsr popax
  jsr url_download
  bcs error
  sec
  lda resource_buffer
  sbc url_download_buffer
  tay
  lda resource_buffer+1
  sbc url_download_buffer+1
  tax
  tya
  rts

error:
  ldx #$00
  txa
  rts

_url_ip := url_ip

_url_port := url_port

_url_selector := url_selector
