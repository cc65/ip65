;this is some very quick and dirty glue to make the most useful IP65 functions available via a single entry point.
;this allows user applications to be developed that don't link ip65 in directly, rather they use an instance of ip65 that is preloaded (or in a cartridge/ROM)
;this whole file could (and should) be greatly optimised by making it all table driven, but since this file is probably only going to be used in a bankswitched ROM where
;space is not at such a premium, I'll go with the gross hack for now.


.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif
.include "../inc/common.i"
.include "../inc/commonprint.i"
.export kipper_dispatcher

.import ip65_init
.import dhcp_init
.import cfg_get_configuration_ptr
.import tftp_load_address
.importzp tftp_filename
.import tftp_ip
.import ip65_error
.import tftp_clear_callbacks
.import tftp_download
.import tftp_upload
.import tftp_set_callback_vector
.import tftp_filesize
.import dns_ip
.import dns_resolve
.import dns_set_hostname
.import udp_callback
.import udp_add_listener
.import udp_remove_listener
.import ip_inp
.import udp_inp
.import udp_send
.import udp_send_src
.import udp_send_src_port
.import udp_send_dest
.import udp_send_dest_port
.import udp_send_len

.import copymem
.import cfg_mac
.import cfg_tftp_server
.importzp copy_src
.importzp copy_dest

;reuse the copy_src zero page location
kipper_params = copy_src
buffer_ptr= copy_dest
.data



ip_configured_flag:
  .byte 0

.code


set_tftp_params:
    ldx #$03
:
  lda cfg_tftp_server,x
  sta tftp_ip,x
  dex
  bpl :-

  ldy #KPR_TFTP_FILENAME
  lda (kipper_params),y
  sta tftp_filename
  iny
  lda (kipper_params),y
  sta tftp_filename+1

  ldy #KPR_TFTP_POINTER
  lda (kipper_params),y
  sta tftp_load_address
  iny
  lda (kipper_params),y
  sta tftp_load_address+1
  
  jsr tftp_clear_callbacks
  
  rts

set_tftp_callback_vector:
  ldy #KPR_TFTP_POINTER+1
  lda (kipper_params),y
  tax
  dey
  lda (kipper_params),y  
  jmp tftp_set_callback_vector
  
kipper_dispatcher:
  stax kipper_params
  

  cpy #KPR_INITIALIZE
  bne :+
  lda ip_configured_flag
  bne ip_configured
  jsr ip65_init
  bcs init_failed
  jsr dhcp_init
  bcc dhcp_ok
  jsr ip65_init   ;if DHCP failed, then reinit the IP stack (which will reset IP address etc that DHCP messed with to cartridge default values)
dhcp_ok:  
  lda #1
  sta ip_configured_flag
  clc
init_failed:  
  rts
  
ip_configured:
  clc
  rts
:

  cpy #KPR_GET_IP_CONFIG
  bne :+
  ldax  #cfg_mac
  clc
  rts
:

  cpy #KPR_DNS_RESOLVE
  bne :+  
  phax
  ldy #KPR_DNS_HOSTNAME+1
  lda (kipper_params),y
  tax
  dey
  lda (kipper_params),y
  jsr dns_set_hostname 
  bcs @dns_error
  jsr dns_resolve
  bcs @dns_error

  ldy #KPR_DNS_HOSTNAME_IP  
  plax
  stax kipper_params
  ldx #4
@copy_dns_ip:
  lda dns_ip,y
  sta (kipper_params),y
  iny
  dex  
  bne @copy_dns_ip
  rts
@dns_error:
  plax
  rts
    
:

  cpy #KPR_UDP_ADD_LISTENER
  bne :+  
  ldy #KPR_UDP_LISTENER_CALLBACK
  lda (kipper_params),y
  sta udp_callback
  iny
  lda (kipper_params),y
  sta udp_callback+1
  ldy #KPR_UDP_LISTENER_PORT+1
  lda (kipper_params),y
  tax
  dey
  lda (kipper_params),y
  
  jmp udp_add_listener
:

  cpy #KPR_GET_INPUT_PACKET_INFO
  bne :+
  ldy #3
@copy_src_ip:  
  lda ip_inp+12,y  ;src IP 
  sta (kipper_params),y
  dey
  bpl @copy_src_ip
  
  ldy #KPR_REMOTE_PORT
  lda udp_inp+1 ;src port (lo byte)
  sta (kipper_params),y
  iny
  lda udp_inp+0 ;src port (high byte)
  sta (kipper_params),y
  iny
  lda udp_inp+3 ;dest port (lo byte)
  sta (kipper_params),y
  iny
  lda udp_inp+2 ;dest port (high byte)
  sta (kipper_params),y

  iny
  sec
  lda udp_inp+5 ;payload length (lo byte)
  sbc #8  ;to remove length of header
  sta (kipper_params),y

  iny
  lda udp_inp+4 ;payload length (hi byte)
  sbc #0  ;in case there was a carry from the lo byte
  sta (kipper_params),y
  
  iny
  lda #<(udp_inp+8) ;payload ptr (lo byte)
  sta (kipper_params),y

  iny
  lda #>(udp_inp+8) ;payload ptr (hi byte)
  sta (kipper_params),y

.import tcp_inbound_data_ptr
.import tcp_inbound_data_length

  lda ip_inp+9 ;proto number
  cmp #6  ;TCP
  bne @not_tcp
  ldy #KPR_PAYLOAD_LENGTH
  lda tcp_inbound_data_length
  sta (kipper_params),y
  iny
  lda tcp_inbound_data_length+1
  sta (kipper_params),y
  
  ldy #KPR_PAYLOAD_POINTER
  lda tcp_inbound_data_ptr
  sta (kipper_params),y
  iny
  lda tcp_inbound_data_ptr+1
  sta (kipper_params),y
@not_tcp:

  clc
  rts
:  

  cpy #KPR_SEND_UDP_PACKET
  bne :+
  ldy #3
@copy_dest_ip:  
  lda (kipper_params),y
  sta udp_send_dest,y
  dey
  bpl @copy_dest_ip
  
  ldy #KPR_REMOTE_PORT  
  lda (kipper_params),y
  sta udp_send_dest_port
  iny
  lda (kipper_params),y
  sta udp_send_dest_port+1
  iny

  lda (kipper_params),y
  sta udp_send_src_port
  iny
  lda (kipper_params),y
  sta udp_send_src_port+1
  iny


  lda (kipper_params),y
  sta udp_send_len
  iny
  lda (kipper_params),y
  sta udp_send_len+1
  iny

  ;AX should point at data to send
  lda (kipper_params),y
  pha
  iny
  lda (kipper_params),y  
  tax
  pla
  jmp udp_send
:

  cpy #KPR_UDP_REMOVE_LISTENER
  bne :+
  jmp udp_remove_listener
:  


  cpy #KPR_DEACTIVATE
  ;nothing to do now we don't use IRQ
  bne :+
  clc
  rts
:  

  cpy #KPR_TFTP_SET_SERVER
  bne :+
  ldy #3
@copy_tftp_server_ip:  
  lda (kipper_params),y
  sta cfg_tftp_server,y
  dey
  bpl @copy_tftp_server_ip
  clc
  rts
  
:
  cpy #KPR_TFTP_DOWNLOAD
  bne :+
  phax
  jsr set_tftp_params
  jsr tftp_download

@after_tftp_call:  ;write the current load address back to the param buffer (so if $0000 was passed in, the caller can find out the actual value used)
  plax
  bcs @tftp_error
  stax kipper_params

  ldy #KPR_TFTP_POINTER
  lda tftp_load_address
  sta (kipper_params),y  
  iny
  lda tftp_load_address+1
  sta (kipper_params),y

  ldy #KPR_TFTP_FILESIZE
  lda tftp_filesize
  sta (kipper_params),y  
  iny
  lda tftp_filesize+1
  sta (kipper_params),y
  clc
@tftp_error:   
  rts
:



  cpy #KPR_TFTP_CALLBACK_DOWNLOAD
  bne :+
  phax
  jsr set_tftp_params
  jsr set_tftp_callback_vector
  jsr tftp_download
  jmp @after_tftp_call
:

  cpy #KPR_TFTP_UPLOAD
  bne :+
  phax
  jsr set_tftp_params
  ldy #KPR_TFTP_POINTER
  lda (kipper_params),y
  sta tftp_filesize
  iny
  lda (kipper_params),y  
  sta tftp_filesize+1
  
  jsr tftp_download
  jmp @after_tftp_call
:

  cpy #KPR_TFTP_CALLBACK_UPLOAD
  bne :+
  jsr set_tftp_params
  jsr set_tftp_callback_vector
  jmp tftp_upload
:

  cpy #KPR_PRINT_ASCIIZ
  bne :+
  jsr print
  clc
  rts
:  

  cpy #KPR_PRINT_HEX
  bne :+
  jsr print_hex
  clc
  rts
:  

  cpy #KPR_PRINT_DOTTED_QUAD
  bne :+
  jsr print_dotted_quad
  clc
  rts
:  

  cpy #KPR_PRINT_IP_CONFIG
  bne :+
  jsr print_ip_config
  clc
  rts
:

  cpy #KPR_PRINT_INTEGER
  bne :+
  jsr print_integer
  clc
  rts
:


  .segment "TCP_VARS"
    port_number: .res 2
    nonzero_octets: .res 1
  .code

  cpy #KPR_DOWNLOAD_RESOURCE
  bne :+  
.import url_download
.import url_download_buffer
.import url_download_buffer_length


  ldy #KPR_URL_DOWNLOAD_BUFFER
  lda (kipper_params),y
  sta url_download_buffer
  iny
  lda (kipper_params),y
  sta url_download_buffer+1

  ldy #KPR_URL_DOWNLOAD_BUFFER_LENGTH
  lda (kipper_params),y
  sta url_download_buffer_length
  iny
  lda (kipper_params),y
  sta url_download_buffer_length+1
  
  ldy #KPR_URL+1
  lda (kipper_params),y
  tax
  dey
  lda (kipper_params),y
  jmp url_download
:

  cpy #KPR_FILE_LOAD
bne :+  
.import  io_device_no
.import io_read_file
.import io_filename
.import io_filesize
.import io_load_address
  phax
  ldy #KPR_FILE_ACCESS_FILENAME
  lda (kipper_params),y
  sta io_filename
  iny
  lda (kipper_params),y
  sta io_filename+1

  ldy #KPR_FILE_ACCESS_DEVICE
  lda (kipper_params),y
  sta io_device_no

  ldy #KPR_FILE_ACCESS_POINTER+1
  lda (kipper_params),y
  tax
  dey
  lda (kipper_params),y
  jsr io_read_file
  plax
  bcc @read_file_ok
  rts
  
@read_file_ok:  
  stax kipper_params

  ldy #KPR_FILE_ACCESS_POINTER
  lda io_load_address
  sta (kipper_params),y
  iny
  lda io_load_address+1
  sta (kipper_params),y

  ldy #KPR_FILE_ACCESS_FILESIZE
  lda io_filesize
  sta (kipper_params),y
  iny
  lda io_filesize+1
  sta (kipper_params),y
  rts
:

  
  cpy #KPR_HTTPD_START
  bne :+  
  .import httpd_start
  jmp httpd_start
:

cpy #KPR_HTTPD_GET_VAR_VALUE
  bne :+  
  .import http_get_value
  jmp http_get_value
:



  cpy #KPR_PING_HOST
  .import icmp_echo_ip
  .import icmp_ping
  bne :+  
  ldy #3
@copy_ping_ip_loop:
  lda (kipper_params),y
  sta icmp_echo_ip,y
  dey
  bpl @copy_ping_ip_loop
  jmp icmp_ping  
  
:  
  cpy #KPR_TCP_CONNECT
  bne :+  
  .import tcp_connect
  .import tcp_callback
  .import tcp_connect_ip
  .import tcp_listen
  ldy #3
  lda #0
  sta nonzero_octets
@copy_dest_ip:  
  lda (kipper_params),y
  beq @octet_was_zero
  inc nonzero_octets
@octet_was_zero:  
  sta tcp_connect_ip,y
  dey
  bpl @copy_dest_ip
  
  ldy #KPR_TCP_CALLBACK
  lda (kipper_params),y
  sta tcp_callback
  iny
  lda (kipper_params),y
  sta tcp_callback+1
  
  ldy #KPR_TCP_PORT+1
  lda (kipper_params),y
  tax
  dey
  lda (kipper_params),y
  ldy nonzero_octets
  bne @outbound_tcp_connection
  jmp tcp_listen
  
@outbound_tcp_connection:  
  jmp tcp_connect

:

  .import tcp_send
  .import tcp_send_data_len
  cpy #KPR_SEND_TCP_PACKET
  bne :+
  ldy #KPR_TCP_PAYLOAD_LENGTH
  lda (kipper_params),y
  sta tcp_send_data_len
  iny
  lda (kipper_params),y
  sta tcp_send_data_len+1
  ldy #KPR_TCP_PAYLOAD_POINTER+1
  lda (kipper_params),y
  tax
  dey
  lda (kipper_params),y
  jmp tcp_send

:


.import tcp_close
  cpy #KPR_TCP_CLOSE_CONNECTION
  bne :+
  jmp tcp_close
:


.import filter_dns
.import get_filtered_input
.import filter_number

  cpy #KPR_INPUT_STRING
  bne :+
  ldy #40 ;max chars
  ldax #$0000
  jmp get_filtered_input
:

  cpy #KPR_INPUT_HOSTNAME  
  bne :+
  ldy #40 ;max chars
  ldax #filter_dns
  jmp get_filtered_input
:

cpy #KPR_INPUT_PORT_NUMBER
  bne :+
  ldy #5 ;max chars
  ldax #filter_number
  jsr get_filtered_input  
  bcs @no_port_entered
  
  ;AX now points a string containing port number    
  .import parse_integer
  jmp parse_integer
  
@no_port_entered:
  rts
:

cpy #KPR_BLOCK_COPY
  bne :+
  ;this is where we pay the price for trying to save a few 'zero page' pointers 
  ;by reusing the 'copy_src' and 'copy_dest' addresses!
.segment "TCP_VARS"
  tmp_copy_src: .res 2
  tmp_copy_dest: .res 2
  tmp_copy_length: .res 2
.code
  
  ldy #KPR_BLOCK_SRC
  lda (kipper_params),y
  sta tmp_copy_src
  iny  
  lda (kipper_params),y
  sta tmp_copy_src+1
  
  ldy #KPR_BLOCK_DEST
  lda (kipper_params),y
  sta tmp_copy_dest
  iny  
  lda (kipper_params),y
  sta tmp_copy_dest+1

  ldy #KPR_BLOCK_SIZE
  lda (kipper_params),y
  sta tmp_copy_length
  iny  
  lda (kipper_params),y
  sta tmp_copy_length+1

  ldax tmp_copy_src
  stax  copy_src
  ldax tmp_copy_dest
  stax  copy_dest
  ldax tmp_copy_length
  jmp copymem
:

  cpy #KPR_PARSER_INIT
  bne :+
  .import parser_init
  jmp parser_init
:

  cpy #KPR_PARSER_SKIP_NEXT
  bne :+
  .import parser_skip_next
  jmp parser_skip_next
:



  cpy #KPR_GET_LAST_ERROR
  bne :+
  lda ip65_error
  clc
  rts
:  


;default function handler
  lda #KPR_ERROR_FUNCTION_NOT_SUPPORTED
  sta ip65_error
  sec        ;carry flag set = error
  rts


;-- LICENSE FOR function_dispatcher.s --
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
