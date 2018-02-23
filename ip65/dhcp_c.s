.include "../inc/common.inc"

.export _dhcp_init

.import dhcp_init

_dhcp_init:
  jsr dhcp_init
  ldx #$00
  txa
  rol
  rts
