.include "../inc/common.inc"

.export exit_to_basic

.import timer_exit
.import print
.import get_key


.data

press_any_key:
  .byte "Press any key to return to DOS ",0


.code

exit_to_basic:
  jsr timer_exit
  ldax #press_any_key
  jsr print
  jmp get_key



; -- LICENSE FOR atrkernal.s --
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
