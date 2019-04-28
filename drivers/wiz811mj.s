; WIZ811MJ driver

.export _w5100_driver_name
.export _w5100_driver_io_base


__CBM__ = 1
DYN_DRV = 0

.include "w5100.s"


.rodata

_w5100_driver_name:
  .byte "WIZ811MJ",0


.data

_w5100_driver_io_base:
  .word $de00



; -- LICENSE FOR wiz811mj.s --
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
