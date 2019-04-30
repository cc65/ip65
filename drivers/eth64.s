; ETH64 driver

.export _lan91c96_driver_name
.export _lan91c96_driver_io_base


__C64__ = 1
DYN_DRV = 0

.include "lan91c96.s"


.rodata

_lan91c96_driver_name:
  .byte "ETH64",0


.data

_lan91c96_driver_io_base:
  .word $de00



; -- LICENSE FOR eth64.s --
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
