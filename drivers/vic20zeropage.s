; zero page definitions

.exportzp copy_src
.exportzp copy_dest
.exportzp dns_hostname
.exportzp tftp_filename
.exportzp buffer_ptr
.exportzp eth_packet

copy_src      = $5F             ; also $60 - source pointer
copy_dest     = $61             ; also $62 - destination pointer
dns_hostname  = $63             ; also $64
tftp_filename = $65             ; also $66 - name of file to d/l or filemask to get directory listing for
buffer_ptr    = $67             ; also $68 - source pointer
eth_packet    = $69             ; also $6A



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
