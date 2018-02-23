.include "../inc/common.inc"

.export _udp_add_listener
.export _udp_remove_listener
.export _udp_recv_buf
.export _udp_recv_len
.export _udp_recv_src
.export _udp_recv_src_port
.export _udp_send

.import udp_add_listener
.import udp_remove_listener
.import ip_inp
.import udp_inp
.import udp_send

.import udp_callback
.importzp ip_src
.importzp udp_src_port
.importzp udp_len
.importzp udp_data
.import udp_send_len
.import udp_send_dest
.import udp_send_dest_port
.import udp_send_src_port

.import popax, popeax
.importzp sreg

_udp_add_listener:
  stax udp_callback
  jsr popax
  jsr udp_add_listener
  ldx #$00
  txa
  rol
  rts

_udp_remove_listener:
  jsr udp_remove_listener
  ldx #$00
  txa
  rol
  rts

_udp_recv_buf := udp_inp+udp_data

_udp_recv_len:
  lda udp_inp+udp_len+1
  ldx udp_inp+udp_len
  sec
  sbc #udp_data
  bcs :+
  dex
: rts

_udp_recv_src:
  ldax ip_inp+ip_src+2
  stax sreg
  ldax ip_inp+ip_src
  rts

_udp_recv_src_port:
  lda udp_inp+udp_src_port+1
  ldx udp_inp+udp_src_port
  rts

  _udp_send:
  stax udp_send_src_port
  jsr popax
  stax udp_send_dest_port
  jsr popeax
  stax udp_send_dest
  ldax sreg
  stax udp_send_dest+2
  jsr popax
  stax udp_send_len
  jsr popax
  jsr udp_send
  ldx #$00
  txa
  rol
  rts
