.include "../inc/common.inc"
.include "../inc/error.inc"

.export ip65_strerror


.code

;convert error code into a string describing the error
;inputs:
; A = error code
;outputs:
; AX = pointer to zero terminated string describing the error
ip65_strerror:
  cmp #IP65_ERROR_PORT_IN_USE
  bne :+
  ldax #str_port_in_use
  rts

: cmp #IP65_ERROR_TIMEOUT_ON_RECEIVE
  bne :+
  ldax #str_timeout_on_receive
  rts

: cmp #IP65_ERROR_TRANSMIT_FAILED
  bne :+
  ldax #str_transmit_failed
  rts

: cmp #IP65_ERROR_TRANSMISSION_REJECTED_BY_PEER
  bne :+
  ldax #str_transmission_rejected_by_peer
  rts

: cmp #IP65_ERROR_NAME_TOO_LONG
  bne :+
  ldax #str_name_too_long
  rts

: cmp #IP65_ERROR_DEVICE_FAILURE
  bne :+
  ldax #str_device_failure
  rts

: cmp #IP65_ERROR_ABORTED_BY_USER
  bne :+
  ldax #str_aborted_by_user
  rts

: cmp #IP65_ERROR_LISTENER_NOT_AVAILABLE
  bne :+
  ldax #str_listener_not_available
  rts

: cmp #IP65_ERROR_CONNECTION_RESET_BY_PEER
  bne :+
  ldax #str_connection_reset_by_peer
  rts

: cmp #IP65_ERROR_CONNECTION_CLOSED
  bne :+
  ldax #str_connection_closed
  rts

: cmp #IP65_ERROR_MALFORMED_URL
  bne :+
  ldax #str_malformed_url
  rts

: cmp #IP65_ERROR_DNS_LOOKUP_FAILED
  bne :+
  ldax #str_dns_lookup_failed
  rts

: ldax #str_unknown
  rts


.rodata

str_port_in_use:
  .byte "Port in use",0

str_timeout_on_receive:
  .byte "Timeout",0

str_transmit_failed:
  .byte "Send failed",0

str_transmission_rejected_by_peer:
  .byte "Data rejected",0

str_name_too_long:
  .byte "Name too long",0

str_device_failure:
  .byte "No device found",0

str_aborted_by_user:
  .byte "User abort",0

str_listener_not_available:
  .byte "No more listener",0

str_connection_reset_by_peer:
  .byte "Connection reset by peer",0

str_connection_closed:
  .byte "Connection closed",0

str_malformed_url:
  .byte "Malformed URL",0

str_dns_lookup_failed:
  .byte "Lookup failed",0

str_unknown:
  .byte "Unknown error",0



; -- LICENSE FOR error.s --
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
; The Initial Developer of the Original Code is Per Olofsson,
; MagerValp@gmail.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Per Olofsson. All Rights Reserved.
; -- LICENSE END --
