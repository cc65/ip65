; constants for accessing the KPR API file
; to use this file under CA65 add ".define EQU =" to your code before this file is included.

KPR_API_VERSION_NUMBER EQU $01

; error codes (as returned by KPR_GET_LAST_ERROR)
KPR_ERROR_PORT_IN_USE                   EQU $80
KPR_ERROR_TIMEOUT_ON_RECEIVE            EQU $81
KPR_ERROR_TRANSMIT_FAILED               EQU $82
KPR_ERROR_TRANSMISSION_REJECTED_BY_PEER EQU $83
KPR_ERROR_INPUT_TOO_LARGE               EQU $84
KPR_ERROR_DEVICE_FAILURE                EQU $85
KPR_ERROR_ABORTED_BY_USER               EQU $86
KPR_ERROR_LISTENER_NOT_AVAILABLE        EQU $87
KPR_ERROR_CONNECTION_RESET_BY_PEER      EQU $89
KPR_ERROR_CONNECTION_CLOSED             EQU $8A
KPR_ERROR_MALFORMED_URL                 EQU $A0
KPR_ERROR_DNS_LOOKUP_FAILED             EQU $A1



; -- LICENSE FOR kipper_constants.i --
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
