.bss

;global scratch buffer that DHCP/DNS/TFTP and others can use while building outbound packets.
;you need to be careful if using this that you don't call a function that also uses it.
;if this is reserved for higher level protocols, the likelyhood of collision is low.
.export output_buffer
output_buffer: .res 520


;-- LICENSE FOR output_buffer.s --
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
