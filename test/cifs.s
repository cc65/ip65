  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  
  .import exit_to_basic  
  
  .import cfg_get_configuration_ptr
  .import cifs_l1_encode 
  .import cifs_l1_decode
  .import cifs_start
  
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__
  .import  __DATA_SIZE__
  .import  __IP65_DEFAULTS_SIZE__
  

	.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

	.word basicstub		; load address

basicstub:
	.word @nextline
	.word 2003
	.byte $9e
	.byte <(((init / 1000) .mod 10) + $30)
	.byte <(((init / 100 ) .mod 10) + $30)
	.byte <(((init / 10  ) .mod 10) + $30)
	.byte <(((init       ) .mod 10) + $30)
	.byte 0
@nextline:
	.word 0

.segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-$11                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+__IP65_DEFAULTS_SIZE__+4	; Size
        jmp init

.code

init:
  lda #$0E    ;change to lower case
  jsr print_a 
  jsr print_cr
  init_ip_via_dhcp 

;  jsr ip65_init
  
  ldx #3
:  
  lda static_ip,x
  sta cfg_ip,x
  dex
  bpl :-
  
  jsr print_ip_config
  
  ldax #hostname_1
  jsr do_encoding_test  

  ldax #hostname_2
  jsr do_encoding_test  

  ldax #hostname_3
  jsr do_encoding_test  
  
  ldax  #cifs_hostname
  jsr cifs_start
  jmp exit_to_basic


do_encoding_test:
  stax hostname_ptr
  jsr print
  lda #' '
  jsr print_a
  lda #':'
  jsr print_a
  lda #' '
  jsr print_a
  ldax hostname_ptr
  jsr cifs_l1_encode
  stax hostname_ptr
  jsr print
  jsr print_cr
  ldax hostname_ptr
  jsr cifs_l1_decode
  jsr print
  jsr print_cr
  rts



	.rodata


hostname_ptr: .res 2
hostname_1:
  .byte "Neko",0          ;this should be an A record

hostname_2:
  .byte "NEKO",0   ;this should be a CNAME

hostname_3:
  .byte "HOSTNAMEWITHLOTSOFCHARSINNAME",0     ;this should be another CNAME

cifs_hostname:
  .byte "KIPPERCIFS",0

static_ip:
  .byte 10,5,1,64
sample_msg:
.byte  $ff, $ff, $ff, $ff, $ff, $ff, $f8, $1e, $df, $dc, $47, $a1, $08, $00, $45, $00
.byte  $00, $4e, $9e, $cf, $00, $00, $40, $11, $c4, $c5, $0a, $05, $01, $02, $0a, $05 
.byte  $01, $ff, $fe, $66, $00, $89, $00, $3a, $86, $0a, $00, $02, $01, $10, $00, $01 
.byte  $00, $00, $00, $00, $00, $00, $20, $45, $48, $45, $50, $45, $50, $45, $43, $45 
.byte  $46, $46, $43, $43, $41, $43, $41, $43, $41, $43, $41, $43, $41, $43, $41, $43 
.byte  $41, $43, $41, $43, $41, $43, $41, $00, $00, $20, $00, $01



;-- LICENSE FOR testdns.s --
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
