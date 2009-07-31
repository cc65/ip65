;A2 telnet
;july 2009 (at Mt Keira Fest!) - jonno @ jamtronix.com

  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  .include "../inc/a2keycodes.i" 
 
  
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__
  .import  __DATA_SIZE__

  .import get_key
  .import cls

.import telnet_connect
.import telnet_local_echo
.import telnet_line_mode
.import telnet_use_native_charset
.import telnet_port
.import telnet_ip
.import cfg_init

.import dns_ip
.import dns_resolve
.import dns_set_hostname
.import get_filtered_input
.import filter_dns
.import filter_number

  .segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-3                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; Size
        jmp init

 	.segment "IP65ZP" : zeropage

buffer_ptr: .res 2

.code

init:
  
  jsr cls
  jsr $c300
  ldax #title
  jsr print
  jsr print_cr
  init_ip_via_dhcp 
  jsr print_ip_config

  jmp telnet_main_entry
  
exit_telnet:
  jmp $e000
 

telnet_main_entry:
;prompt for a hostname, then resolve to an IP address
  
  ldax #remote_host
  jsr print
  ldax #filter_dns  
  jsr get_filtered_input
  bcc @host_entered
  ;if no host entered, then bail.
  jmp exit_telnet
@host_entered:
  stax hostname_ptr
  jsr print_cr
  ldax #resolving
  jsr print
  ldax hostname_ptr
  jsr print
  jsr print_cr
  ldax hostname_ptr
  jsr dns_set_hostname
  bcs :+    
  jsr dns_resolve
:  
  bcc @resolved_ok
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
  jsr get_port_number
  bcc @port_entered
  ;if no port entered, then assume port 23
  ldax #23
@port_entered:
  stax telnet_port
  jsr print_cr
  
  ldax #char_mode_prompt
  jsr print
@char_mode_input:
  jsr get_key
  cmp #'A'
  beq @ascii_mode
  cmp #'a'
  beq @ascii_mode

  cmp #'N'
  beq @native_mode
  cmp #'n'
  beq @native_mode
  
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
@native_mode:
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
  
  jsr cls
  
  ldax  #connecting_in
  jsr print
  lda  telnet_use_native_charset
  beq @a_mode
  ldax #native
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


get_port_number:
  .import mul_8_16
  .importzp acc16
  
  ldy #5 ;max chars
  ldax #filter_number
  jsr get_filtered_input  
  bcs @no_port_entered
  
  ;AX now points a string containing port number
    
  stax  buffer_ptr
  lda #0
  sta port_number
  sta port_number+1
  tay
@parse_port:
  lda (buffer_ptr),y
  cmp #$1F
  bcc @end_of_port  ;any control char should be treated as end of port field  
  ldax  port_number
  stax  acc16
  lda #10
  jsr mul_8_16
  ldax  acc16
  stax  port_number
  lda (buffer_ptr),y
  sec
  sbc #'0'
  clc
  adc port_number
  sta port_number
  bcc @no_rollover  
  inc port_number+1
@no_rollover:
  iny
  bne @parse_port
@end_of_port:  
  ldax port_number
  clc
@no_port_entered:
  rts


.bss
hostname_ptr: .res 2
port_number: .res 2
.rodata
title: .byte "                 TELNET ][",13,"           jonno@jamtronix.com",13,0
resolving: .byte "RESOLVING ",0
connecting_in: .byte "CONNECTING IN ",0
ascii: .byte "ASCII",0
native: .byte "NATIVE",0
line: .byte "LINE",0
mode: .byte " MODE",13,0
remote_host: .byte "HOSTNAME (LEAVE BLANK TO QUIT)",13,": ",0
remote_port: .byte "PORT # (LEAVE BLANK FOR DEFAULT)",13,": ",0
char_mode_prompt: .byte "MODE - A=ASCII, N=NATIVE, L=LINE",13,0


