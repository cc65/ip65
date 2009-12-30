;telnet routines
; to use:
; 1) include this file 
; 2) include these other files:
;  .include "../inc/common.i"
;  .include "../inc/commonprint.i"
;  .include "../inc/net.i"
; 3) define a routine called 'exit_telnet'

.import telnet_connect
.import telnet_use_native_charset
.import telnet_port
.import telnet_ip
.import filter_number

.export telnet_on_connection

.bss
original_border: .res 1

.code
telnet_main_entry:
;prompt for a hostname, then resolve to an IP address
  
  ldax #remote_host
  jsr print_ascii_as_native
  ldy #40 ;max chars
  ldax #filter_dns
  jsr get_filtered_input
  bcc @host_entered
  ;if no host entered, then bail.
  jmp exit_telnet
@host_entered:
  stax temp_ax
  jsr print_cr
  ldax #resolving
  jsr print_ascii_as_native
  ldax temp_ax
  jsr print
  jsr print_cr
  ldax temp_ax
  jsr dns_set_hostname 
  bcs @resolve_error  
  jsr dns_resolve
  bcc @resolved_ok
@resolve_error:
  print_failed
  jsr print_cr
  jsr print_errorcode
  jmp telnet_main_entry
@resolved_ok:
  ldx #3
@copy_telnet_ip_loop:
  lda dns_ip,x
  sta telnet_ip,x
  dex
  bpl @copy_telnet_ip_loop
@get_port:
  ldax #remote_port
  jsr print_ascii_as_native
  ldy #5 ;max chars
  ldax #filter_number
  jsr get_filtered_input  
  bcs @no_port_entered  
  ;AX now points a string containing port number    
  jsr parse_integer
  bcc @port_entered
@no_port_entered:  
  ;if no port entered, then assume port 23
  ldax #23
@port_entered:
  stax telnet_port
  jsr print_cr

  ldax #char_mode_prompt
  jsr print_ascii_as_native
@char_mode_input:
  jsr get_key_ip65
  cmp #'V'
  beq @vt100_mode
  cmp #'v'
  beq @vt100_mode

  cmp #'P'
  beq @petscii_mode
  cmp #'p'
  beq @petscii_mode
  
  jmp @char_mode_input
@vt100_mode:
  lda #0
  sta telnet_use_native_charset
      
.ifdef XMODEM_IN_TELNET
  lda #1
  sta xmodem_iac_escape
.endif
  jmp @after_mode_set
@petscii_mode:
  lda #1
  sta telnet_use_native_charset
  
.ifdef XMODEM_IN_TELNET
  lda #0
  sta xmodem_iac_escape
.endif  

@after_mode_set:
  
  lda #147  ; 'CLR/HOME'
  jsr print_a
  
  ldax  #connecting_in
  jsr print_ascii_as_native
  lda  telnet_use_native_charset
  beq @v_mode
  ldax #petscii
  jmp @c_mode
@v_mode:
  ldax #vt100
@c_mode:
  jsr print_ascii_as_native  
  ldax #mode
  jsr print_ascii_as_native

  lda $d020
  sta original_border
  
  jsr telnet_connect  
  
  lda original_border
  sta $d020
  ;reset the background colour
  
  jmp telnet_main_entry  

telnet_on_connection:
  ;toggle the background colour
  dec $d020
  rts
  
;constants
connecting_in: .byte "connecting in ",0
vt100: .byte "vt100",0
petscii: .byte "petscii",0
mode: .byte " mode",10,0
remote_host: .byte "hostname (leave blank to quit)",10,": ",0
remote_port: .byte "port # (leave blank for default)",10,": ",0
char_mode_prompt: .byte "mode - V=vt100, P=petscii",10,0




;-- LICENSE FOR telnet.i --
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
