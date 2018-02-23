.include "../inc/common.inc"

.export _sntp_get_time

.import sntp_get_time
.import sntp_ip
.import sntp_utc_timestamp

.importzp sreg

_sntp_get_time:
  stax sntp_ip
  ldax sreg
  stax sntp_ip+2
  jsr sntp_get_time
  bcs error
  ldax sntp_utc_timestamp+2
  stax sreg
  ldax sntp_utc_timestamp
  rts

error:
  ldx #$00
  txa
  stax sreg
  rts
