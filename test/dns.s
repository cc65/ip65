.include "../inc/common.i"
.include "../inc/commonprint.i"
.include "../inc/net.i"

.import exit_to_basic

.import dns_set_hostname
.import dns_resolve
.import dns_ip
.import dns_status
.import cfg_get_configuration_ptr


; keep LD65 happy
.segment "ZPSAVE"


.segment "STARTUP"

  ; switch to lower case charset
  lda #14
  jsr print_a

  jsr print_cr
  init_ip_via_dhcp
; jsr overwrite_with_hardcoded_dns_server
  jsr print_ip_config

  ldax #hostname_1
  jsr do_dns_query

  ldax #hostname_2
  jsr do_dns_query

  ldax #hostname_3
  jsr do_dns_query

  ldax #hostname_4
  jsr do_dns_query

  ldax #hostname_5
  jsr do_dns_query

  ldax #hostname_6
  jsr do_dns_query

  jmp exit_to_basic

do_dns_query:
  pha
  jsr print
  lda #' '
  jsr print_a
  lda #':'
  jsr print_a
  lda #' '
  jsr print_a
  pla
  jsr dns_set_hostname
  jsr dns_resolve
  bcc :+
  ldax #dns_lookup_failed_msg
  jsr print
  jmp @print_dns_status
: ldax #dns_ip
  jsr print_dotted_quad
@print_dns_status:
  jsr print_cr
  lda dns_status
  jsr print_hex
  lda dns_status+1
  jsr print_hex
  jsr print_cr
  rts

overwrite_with_hardcoded_dns_server:
  ldx #3
: lda hardcoded_dns_server,x
  sta cfg_dns,x
  dex
  bpl :-
  rts


.rodata

hostname_1:
  .byte "SLASHDOT.ORG",0        ; this should be an A record

hostname_2:
  .byte "VICTA.JAMTRONIX.COM",0 ; this should be a CNAME

hostname_3:
  .byte "WWW.JAMTRONIX.COM",0   ; this should be another CNAME

hostname_4:
  .byte "FOO.BAR.BOGUS",0       ; this should fail

hostname_5:
  .byte "111.22.3.4",0          ; this should work (without hitting dns)

hostname_6:
  .byte "3COM.COM",0            ; make sure doesn't get treated as a number

hardcoded_dns_server:
; .byte 61,9,195,193
; .byte 64,127,100,12
  .byte 205,171,3,65
  .byte 69,111,95,106



; -- LICENSE FOR dns.s --
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
