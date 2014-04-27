.export _libnet_init
.export _libnet_get_config

.import cfg_init
.import cfg_ip
.import copymem
.import ip65_init
.import dhcp_init
.import ip65_error
.import cfg_mac

; load A/X macro
.macro ldax arg
.if (.match (.left (1, arg), #))        ; immediate mode
    lda #<(.right (.tcount (arg)-1, arg))
    ldx #>(.right (.tcount (arg)-1, arg))
.else                                   ; assume absolute or zero page
    lda arg
    ldx 1+(arg)
.endif
.endmacro

; store A/X macro
.macro stax arg
  sta arg
  stx 1+(arg)
.endmacro

NO_ERROR = $00

.importzp copy_src
.importzp copy_dest


.code

_libnet_init:
  sta copy_src
  stx copy_src+1
  beq @dhcp_request
  ldax #cfg_ip
  stax copy_dest
  ldax #$10                     ; 4 items of config data
  jsr copymem
  jsr ip65_init
@check_error:
  bcc @ok
  lda ip65_error
  rts
@ok:
  lda #NO_ERROR
  rts

@dhcp_request:
  jsr ip65_init
  jsr dhcp_init
  jmp @check_error

_libnet_get_config:
  stax copy_dest
  ldax #cfg_ip
  stax copy_src
  ldax #$10                     ; 4 items of config data
  jmp copymem


.bss

tmp_ax: .res 2



; -- LICENSE FOR libnet.s --
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
; The Original Code is libnet.
;
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2012
; Jonno DOwnes. All Rights Reserved.
; -- LICENSE END --
