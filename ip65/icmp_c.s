.include "../inc/common.inc"

.export _icmp_ping

.import icmp_echo_ip
.import icmp_ping

.importzp sreg

_icmp_ping:
  stax icmp_echo_ip
  ldax sreg
  stax icmp_echo_ip+2
  jsr icmp_ping
  bcc :+
  ldx #$00
  txa
: rts
