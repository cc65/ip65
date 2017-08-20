.export get_key
.export check_for_abort_key
.export get_key_if_available
.export get_key_ip65
.export abort_key
.exportzp abort_key_default = $3f
.exportzp abort_key_disable = $ff

.import ip65_process


.data

abort_key: .byte $3f            ; RUN/STOP


.code

; use C64 Kernel ROM function to read a key
; inputs: none
; outputs: A contains ASCII value of key just pressed
get_key:
  ldy #0
  sty $cc                       ; cursor on
@loop:
  jsr get_key_if_available
  bcc @loop
  ldy #1
  sty $cc                       ; cursor off
  rts

; use C64 Kernel ROM function to read a key
; inputs: none
; outputs: sec if key pressed, clear otherwise
;          A contains ASCII value of key just pressed
get_key_if_available:
  ldy #$ff
  jsr $f142                     ; not officially documented - where F13E (GETIN) falls through to if device # is 0 (KEYBD)
  cpy #$ff                      ; Y gets modified iff there's a character available - this approach allows to read ^@ as 0
  beq no_key
  sec
  rts

; process inbound ip packets while waiting for a keypress
get_key_ip65:
  jsr ip65_process
  jsr get_key_if_available
  bcc get_key_ip65
  rts

; check whether the abort key is being pressed
; inputs: none
; outputs: sec if abort key pressed, clear otherwise
check_for_abort_key:
  lda $cb                       ; current key pressed
  cmp abort_key
  bne no_key
@flush_loop:
  jsr get_key_if_available
  bcs @flush_loop
  lda $cb                       ; current key pressed
  cmp abort_key
  beq @flush_loop
  sec
  rts
no_key:
  clc
  rts



; -- LICENSE FOR c64input.s --
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
