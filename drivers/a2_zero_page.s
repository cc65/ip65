; zero page definitions
; On the Apple ][ with AppleSoft running there are not enough contiguous zero page locations
; to allow LD65 to handle assignment
; so we need to manually assign ZP pointers to known free locations

.exportzp copy_src
.exportzp copy_dest
.exportzp dns_hostname
.exportzp tftp_filename
.exportzp buffer_ptr
.exportzp eth_packet

copy_src      = $06             ; also $07
copy_dest     = $08             ; also $09
dns_hostname  = $18             ; also $19
tftp_filename = $1D             ; also $1E
buffer_ptr    = $EB             ; also $EC
eth_packet    = $ED             ; also $EE



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
