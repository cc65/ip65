.include "zeropage.inc"

.export drv_init
.exportzp drv_init_default = 3  ; Apple 2 default slot

.import eth_driver_io_base


.code

; set Apple 2 ethernet adaptor slot
; inputs:
; A: slot number (1-7)
; outputs:
; none
drv_init:
  asl
  asl
  asl
  asl
  sta tmp1

  lda eth_driver_io_base
  and #%10001111
  ora tmp1
  sta eth_driver_io_base
  rts



; -- LICENSE FOR a2init.s --
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
