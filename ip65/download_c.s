.include "../inc/common.inc"

.export _url_download

.import url_download
.import url_download_buffer
.import url_download_buffer_length
.import resource_buffer

.import popax

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
