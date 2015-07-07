; RR-Net driver, as seen on a VIC-20 (i.e. using a Masquerade adapter)

.export _cs8900a_driver_name
.export _cs8900a_driver_io_base


.rodata

_cs8900a_driver_name:
  .asciiz "VIC20 RR-Net"


.data

_cs8900a_driver_io_base:
  .word $9808



; -- LICENSE FOR vic20-rr-net.s --
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
