.export get_key
.export check_for_abort_key
.export get_key_if_available
.export get_key_ip65

.import ip65_process


.code

; use C64 Kernel ROM function to read a key
; inputs: none
; outputs: A contains ASCII value of key just pressed
get_key:
  jsr get_key_if_available
  beq get_key
  rts

; use C64 Kernel ROM function to read a key
; inputs: none
; outputs: A contains ASCII value of key just pressed (0 if no key pressed)
get_key_if_available = $f142    ; not officially documented - where F13E (GETIN) falls through to if device # is 0 (KEYBD)

; process inbound ip packets while waiting for a keypress
get_key_ip65:
  jsr ip65_process
  jsr get_key_if_available
  beq get_key_ip65
  rts

; check whether the RUN/STOP key is being pressed
; inputs: none
; outputs: sec if RUN/STOP pressed, clear otherwise
check_for_abort_key:
  lda $cb                       ; current key pressed
  cmp #$3F
  bne @not_abort
@flush_loop:
  jsr get_key_if_available
  bne @flush_loop
  lda $cb                       ; current key pressed
  cmp #$3F
  beq @flush_loop
  sec
  rts
@not_abort:
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
