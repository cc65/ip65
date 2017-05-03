.export get_key
.export check_for_abort_key
.export get_key_ip65
.export get_key_if_available

.import ip65_process


.code

; use Apple 2 monitor ROM function to read from keyboard
; inputs: none
; outputs: A contains ASCII code of key pressed
get_key:
  jmp $fd0c

; inputs: none
; outputs: A contains ASCII value of key just pressed (0 if no key pressed)
get_key_if_available:
  lda $c000                     ; current key pressed
  bmi :+
  lda #0
  rts
: bit $c010                     ; clear the keyboard strobe
  and #$7f
  rts

; check whether the escape key is being pressed
; inputs: none
; outputs: sec if escape pressed, clear otherwise
check_for_abort_key:
  lda $c000                     ; current key pressed
  cmp #$9b
  bne :+
  bit $c010                     ; clear the keyboard strobe
  sec
  rts
: clc
  rts

; process inbound ip packets while waiting for a keypress
get_key_ip65:
  jsr ip65_process
  bit $c000                     ; key down?
  bpl get_key_ip65
  jmp get_key



; -- LICENSE FOR a2input.s --
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
