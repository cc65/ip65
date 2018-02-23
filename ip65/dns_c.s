.include "../inc/common.inc"

.export _dns_resolve

.import dns_set_hostname
.import dns_resolve
.import dns_ip

.importzp sreg

_dns_resolve:
  jsr dns_set_hostname
  bcs error
  jsr dns_resolve
  bcs error
  ldax dns_ip+2
  stax sreg
  ldax dns_ip
  rts

error:
  ldx #$00
  txa
  stax sreg
  rts
