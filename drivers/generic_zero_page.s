; zero page definitions
; this 'generic' file just puts everything into a ZP segment
; and lets LD65 in conjunction with cfg files assign zero page locations
; however this can be overridden in the case that all necessary zp variables
; cant be crammed into a contiguous segment, e.g. on the Apple ][

.exportzp copy_src
.exportzp copy_dest
.exportzp dns_hostname
.exportzp tftp_filename
.exportzp buffer_ptr
.exportzp eth_packet


.segment "IP65ZP" : zeropage

copy_src:      .res 2           ; source pointer
copy_dest:     .res 2           ; destination pointer
dns_hostname:  .res 2
tftp_filename: .res 2           ; name of file to d/l or filemask to get directory listing for
buffer_ptr:    .res 2           ; source pointer
eth_packet:    .res 2



; -- LICENSE --
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
; Portions created by the Initial Developer are Copyright (C) 2013
; Jonno Downes. All Rights Reserved.
; -- LICENSE END --
