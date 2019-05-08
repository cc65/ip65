; Wrapper for combination of Contiki ethernet drivers

.include "zeropage.inc"
.include "../inc/common.inc"

.export eth_init
.export eth_rx
.export eth_tx
.export eth_name

.import eth_inp
.import eth_inp_len
.import eth_outp
.import eth_outp_len

.import _w5100
.import _w5100_name

.import _cs8900a
.import _cs8900a_name

.import _lan91c96
.import _lan91c96_name

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

eth = ptr1


.bss

eth_name:       .res 20
eth_init_value: .res 1


.code

; computes pointer to ethernet driver struct member
; inputs:
; eth: pointer to Contiki ethernet driver
; A: offset of driver struct member
; outputs:
; AX: pointer to ethernet driver struct member
add_driver_offset:
  clc
  adc eth
  ldx eth+1
  bcc :+
  inx
: rts

; increment AX by one
; inputs:
; AX: value to increment
; outputs:
; AX: incremented value
incr_ax:
  clc
  adc #1
  bcc :+
  inx
: rts

; patches Contiki ethernet driver into wrapper code
; inputs:
; AX: pointer to Contiki ethernet driver
; outputs:
; none
patch_wrapper:
  stax eth

  lda #driver::mac
  jsr add_driver_offset
  stax patch_mac+1

  lda #driver::bufaddr
  jsr add_driver_offset
  stax patch_bufaddr_rx+1
  stax patch_bufaddr_tx+1
  jsr incr_ax
  stax patch_bufaddr_rx+4
  stax patch_bufaddr_tx+4

  lda #driver::bufsize
  jsr add_driver_offset
  stax patch_bufsize+1
  jsr incr_ax
  stax patch_bufsize+4

  lda #driver::init
  jsr add_driver_offset
  stax patch_init+1

  lda #driver::poll
  jsr add_driver_offset
  stax patch_poll+1

  lda #driver::send
  jsr add_driver_offset
  stax patch_send+1
  rts

; set ethernet driver name
; inputs:
; AX: pointer to name
; outputs:
; none
set_name:
  stax ptr1
  ldy #18                       ; sizeof(eth_driver_name)-2
: lda (ptr1),y
  sta eth_name,y
  dey
  bpl :-
  rts

; initialize one of the known ethernet adaptors
; inputs: A = adaptor specific initialisation value or 'eth_init_default'
; outputs: carry flag is set if there was an error, clear otherwise
eth_init:
  sta eth_init_value

.if .defined (__APPLE2__) .or .defined (__ATARI__)
  ldax #_w5100
  jsr patch_wrapper
  ldax #_w5100_name
  jsr set_name
  jsr init_adaptor
  bcc @done
.endif

  ldax #_cs8900a
  jsr patch_wrapper
  ldax #_cs8900a_name
  jsr set_name
  jsr init_adaptor
  bcc @done

.if .defined (__C64__) .or .defined (__APPLE2__)
  ldax #_lan91c96
  jsr patch_wrapper
  ldax #_lan91c96_name
  jsr set_name
  jsr init_adaptor
.endif

@done:
  rts


.data

; initialize the ethernet adaptor
; inputs: none
; outputs: carry flag is set if there was an error, clear otherwise
init_adaptor:
  lda eth_init_value
patch_init:
  jsr $ffff                     ; temporary vector - gets filled in later
  ldx #5
patch_mac:
: lda $ffff,x                   ; temporary addr - gets filled in later
  sta cfg_mac,x
  dex
  bpl :-
  ldax #1518
patch_bufsize:
  stax $fffe                    ; temporary addr - gets filled in later
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
patch_bufaddr_rx:
  stax $fffe                    ; temporary addr - gets filled in later
patch_poll:
  jsr $ffff                     ; temporary vector - gets filled in later
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
patch_bufaddr_tx:
  stax $fffe                    ; temporary addr - gets filled in later
  ldax eth_outp_len
patch_send:
  jmp $ffff                     ; temporary vector - gets filled in later



; -- LICENSE FOR ethernetcombo.s --
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
