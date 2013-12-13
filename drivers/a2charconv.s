

.export ascii_to_native
.export native_to_ascii

;given an A2 Screen Code char in A, return equivalent ASCII
native_to_ascii:
;just strip high bit
  and #$7f
  rts

;given an ASCII char in A, return equivalent A2 Screen Code
ascii_to_native:
;set high bit
  ora #$80
  rts




;-- LICENSE FOR a2charconv.s --
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
