; Wrapper for Contiki ethernet driver

.include "../inc/common.inc"

.export eth_init
.export eth_rx
.export eth_tx

.import eth_inp
.import eth_inp_len
.import eth_outp
.import eth_outp_len

.import eth
.import eth_driver_io_base

.import cfg_mac

.struct driver
  drvtype .byte 3
  apiver  .byte
  mac     .byte 6
  bufaddr .addr
  bufsize .word
  init    .byte 3
  poll    .byte 3
  send    .byte 3
  exit    .byte 3
.endstruct


.code

; initialize the ethernet adaptor
; inputs: none
; outputs: carry flag is set if there was an error, clear otherwise
eth_init:
  ldax eth_driver_io_base
  jsr eth+driver::init
  ldx #5
: lda eth+driver::mac,x
  sta cfg_mac,x
  dex
  bpl :-
  ldax #1518
  stax eth+driver::bufsize
  rts

; receive a packet
; inputs: none
; outputs:
; if there was an error receiving the packet (or no packet was ready) then carry flag is set
; if packet was received correctly then carry flag is clear,
; eth_inp contains the received packet,
; and eth_inp_len contains the length of the packet
eth_rx:
  ldax #eth_inp
  stax eth+driver::bufaddr
  jsr eth+driver::poll
  stax eth_inp_len
  rts

; send a packet
; inputs:
; eth_outp: packet to send
; eth_outp_len: length of packet to send
; outputs:
; if there was an error sending the packet then carry flag is set
; otherwise carry flag is cleared
eth_tx:
  ldax #eth_outp
  stax eth+driver::bufaddr
  ldax eth_outp_len
  jmp eth+driver::send



; -- LICENSE FOR ethernet.s --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
;
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
;
; The Original Code is ip65.
;
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.
; -- LICENSE END --
