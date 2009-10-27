;telnet routines
; to use:
; 1) include this file 
; 2) include these other files:
;  .include "../inc/common.i"
;  .include "../inc/commonprint.i"
;  .include "../inc/net.i"
; 3) define a routine called 'exit_telnet'

.import telnet_connect
.import telnet_local_echo
.import telnet_line_mode
.import telnet_use_native_charset
.import telnet_port
.import telnet_ip
.import filter_number

.code
telnet_main_entry:
;prompt for a hostname, then resolve to an IP address
  
  ldax #remote_host
  jsr print
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
  jsr print
  ldax temp_ax
  jsr print
  jsr print_cr
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
  jsr print
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
  jsr print
@char_mode_input:
  jsr get_key_ip65
  cmp #'A'
  beq @ascii_mode
  cmp #'a'
  beq @ascii_mode

  cmp #'P'
  beq @petscii_mode
  cmp #'p'
  beq @petscii_mode
  
  cmp #'l'
  beq @line_mode
  cmp #'L'
  beq @line_mode

  jmp @char_mode_input
@ascii_mode:
  lda #0
  sta telnet_use_native_charset
  sta telnet_line_mode
  lda #1
  sta telnet_local_echo
  jmp @after_mode_set
@petscii_mode:
  lda #1
  sta telnet_use_native_charset
  lda #0
  sta telnet_local_echo
  sta telnet_line_mode
  jmp @after_mode_set
@line_mode:
  lda #0
  sta telnet_use_native_charset
  lda #1
  sta telnet_local_echo
  sta telnet_line_mode
  
@after_mode_set:
  
  lda #147  ; 'CLR/HOME'
  jsr print_a
  
  ldax  #connecting_in
  jsr print
  lda  telnet_use_native_charset
  beq @a_mode
  ldax #petscii
  jmp @c_mode
@a_mode:
  lda telnet_line_mode
  bne @l_mode
  ldax #ascii  
  jmp @c_mode
@l_mode:
  ldax #line  
@c_mode:
  jsr print  
  ldax #mode
  jsr print
  jsr telnet_connect
  jmp telnet_main_entry  
  
;constants
connecting_in: .byte "CONNECTING IN ",0
ascii: .byte "ASCII",0
petscii: .byte "PETSCII",0
line: .byte "LINE",0
mode: .byte " MODE",13,0
remote_host: .byte "HOSTNAME (LEAVE BLANK TO QUIT)",13,": ",0
remote_port: .byte "PORT # (LEAVE BLANK FOR DEFAULT)",13,": ",0
char_mode_prompt: .byte "MODE - A=ASCII, P=PETSCII, L=LINE",13,0




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
