;this is some very quick and dirty glue to make the most useful IP65 functions available via a single entry point.
;this allows user applications to be developed that don't link ip65 in directly, rather they use an instance of ip65 that is preloaded (or in a cartridge/ROM)
;this whole file could (and should) be greatly optimised by making it all table driven, but since this file is probably only going to be used in a bankswitched ROM where
;space is not at such a premium, I'll go with the gross hack for now.

.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif
.include "../inc/common.i"
.include "../inc/commonprint.i"
.export nb65_dispatcher

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
nb65_params = copy_src
buffer_ptr= copy_dest
.data


jmp_old_irq:
  jmp $0000

irq_handler_installed_flag:
  .byte 0

ip_configured_flag:
  .byte 0

.code

irq_handler:
  jsr NB65_VBL_VECTOR
  jmp jmp_old_irq


install_irq_handler:
  ldax  $314    ;previous IRQ handler
  stax  jmp_old_irq+1
  sei ;don't want any interrupts while we fiddle with the vector
  ldax #irq_handler
  stax  $314    ;previous IRQ handler
  sta irq_handler_installed_flag
  cli
  rts
  
set_tftp_params:
    ldx #$03
:
  lda cfg_tftp_server,x
  sta tftp_ip,x
  dex
  bpl :-

  ldy #NB65_TFTP_FILENAME
  lda (nb65_params),y
  sta tftp_filename
  iny
  lda (nb65_params),y
  sta tftp_filename+1

  ldy #NB65_TFTP_POINTER
  lda (nb65_params),y
  sta tftp_load_address
  iny
  lda (nb65_params),y
  sta tftp_load_address+1
  
  jsr tftp_clear_callbacks
  
  rts

set_tftp_callback_vector:
  ldy #NB65_TFTP_POINTER+1
  lda (nb65_params),y
  tax
  dey
  lda (nb65_params),y  
  jmp tftp_set_callback_vector
  
nb65_dispatcher:
  stax nb65_params
  

  cpy #NB65_INITIALIZE
  bne :+
  lda ip_configured_flag
  bne ip_configured
  jsr ip65_init
  bcs init_failed
  jsr install_irq_handler
  jsr dhcp_init
  bcc dhcp_ok
  jsr ip65_init   ;if DHCP failed, then reinit the IP stack (which will reset IP address etc that DHCP messed with to cartridge default values)
dhcp_ok:  
  lda #1
  sta ip_configured_flag
irq_handler_installed:  
  clc
init_failed:  
  rts
  
ip_configured:
  lda irq_handler_installed_flag
  bne irq_handler_installed
  jsr install_irq_handler
  clc
  rts
:

  cpy #NB65_GET_IP_CONFIG
  bne :+
  ldax  #cfg_mac
  clc
  rts
:

  cpy #NB65_DNS_RESOLVE
  bne :+  
  phax
  ldy #NB65_DNS_HOSTNAME+1
  lda (nb65_params),y
  tax
  dey
  lda (nb65_params),y
  jsr dns_set_hostname 
  bcs @dns_error
  jsr dns_resolve
  bcs @dns_error

  ldy #NB65_DNS_HOSTNAME_IP  
  plax
  stax nb65_params
  ldx #4
@copy_dns_ip:
  lda dns_ip,y
  sta (nb65_params),y
  iny
  dex  
  bne @copy_dns_ip
  rts
@dns_error:
  plax
  rts
    
:

  cpy #NB65_UDP_ADD_LISTENER
  bne :+  
  ldy #NB65_UDP_LISTENER_CALLBACK
  lda (nb65_params),y
  sta udp_callback
  iny
  lda (nb65_params),y
  sta udp_callback+1
  ldy #NB65_UDP_LISTENER_PORT+1
  lda (nb65_params),y
  tax
  dey
  lda (nb65_params),y
  
  jmp udp_add_listener
:

  cpy #NB65_GET_INPUT_PACKET_INFO
  bne :+
  ldy #3
@copy_src_ip:  
  lda ip_inp+12,y  ;src IP 
  sta (nb65_params),y
  dey
  bpl @copy_src_ip
  
  ldy #NB65_REMOTE_PORT
  lda udp_inp+1 ;src port (lo byte)
  sta (nb65_params),y
  iny
  lda udp_inp+0 ;src port (high byte)
  sta (nb65_params),y
  iny
  lda udp_inp+3 ;dest port (lo byte)
  sta (nb65_params),y
  iny
  lda udp_inp+2 ;dest port (high byte)
  sta (nb65_params),y

  iny
  sec
  lda udp_inp+5 ;payload length (lo byte)
  sbc #8  ;to remove length of header
  sta (nb65_params),y

  iny
  lda udp_inp+4 ;payload length (hi byte)
  sbc #0  ;in case there was a carry from the lo byte
  sta (nb65_params),y
  
  iny
  lda #<(udp_inp+8) ;payload ptr (lo byte)
  sta (nb65_params),y

  iny
  lda #>(udp_inp+8) ;payload ptr (hi byte)
  sta (nb65_params),y

.ifdef API_VERSION
.if (API_VERSION>1)
.import tcp_inbound_data_ptr
.import tcp_inbound_data_length

;for API V2+, we need to check if this is a TCP packet
  lda ip_inp+9 ;proto number
  cmp #6  ;TCP
  bne @not_tcp
  ldy #NB65_PAYLOAD_LENGTH
  lda tcp_inbound_data_length
  sta (nb65_params),y
  iny
  lda tcp_inbound_data_length+1
  sta (nb65_params),y
  
  ldy #NB65_PAYLOAD_POINTER
  lda tcp_inbound_data_ptr
  sta (nb65_params),y
  iny
  lda tcp_inbound_data_ptr+1
  sta (nb65_params),y
@not_tcp:
.endif
.endif

  clc
  rts
:  

  cpy #NB65_SEND_UDP_PACKET
  bne :+
  ldy #3
@copy_dest_ip:  
  lda (nb65_params),y
  sta udp_send_dest,y
  dey
  bpl @copy_dest_ip
  
  ldy #NB65_REMOTE_PORT  
  lda (nb65_params),y
  sta udp_send_dest_port
  iny
  lda (nb65_params),y
  sta udp_send_dest_port+1
  iny

  lda (nb65_params),y
  sta udp_send_src_port
  iny
  lda (nb65_params),y
  sta udp_send_src_port+1
  iny


  lda (nb65_params),y
  sta udp_send_len
  iny
  lda (nb65_params),y
  sta udp_send_len+1
  iny

  ;AX should point at data to send
  lda (nb65_params),y
  pha
  iny
  lda (nb65_params),y  
  tax
  pla
  jmp udp_send
:

  cpy #NB65_UDP_REMOVE_LISTENER
  bne :+
  jmp udp_remove_listener
:  


  cpy #NB65_DEACTIVATE
  bne :+
  ldax  jmp_old_irq+1
  sei ;don't want any interrupts while we fiddle with the vector
  stax  $314    ;previous IRQ handler
  lda #0
  sta irq_handler_installed_flag 
  cli
  clc
  rts
:  

  cpy #NB65_TFTP_SET_SERVER
  bne :+
  ldy #3
@copy_tftp_server_ip:  
  lda (nb65_params),y
  sta cfg_tftp_server,y
  dey
  bpl @copy_tftp_server_ip
  clc
  rts
  
:
  cpy #NB65_TFTP_DOWNLOAD
  bne :+
  phax
  jsr set_tftp_params
  jsr tftp_download

@after_tftp_call:  ;write the current load address back to the param buffer (so if $0000 was passed in, the caller can find out the actual value used)
  plax
  bcs @tftp_error
  stax nb65_params

  ldy #NB65_TFTP_POINTER
  lda tftp_load_address
  sta (nb65_params),y  
  iny
  lda tftp_load_address+1
  sta (nb65_params),y

  ldy #NB65_TFTP_FILESIZE
  lda tftp_filesize
  sta (nb65_params),y  
  iny
  lda tftp_filesize+1
  sta (nb65_params),y
  clc
@tftp_error:   
  rts
:



  cpy #NB65_TFTP_CALLBACK_DOWNLOAD
  bne :+
  phax
  jsr set_tftp_params
  jsr set_tftp_callback_vector
  jsr tftp_download
  jmp @after_tftp_call
:

  cpy #NB65_TFTP_UPLOAD
  bne :+
  phax
  jsr set_tftp_params
  ldy #NB65_TFTP_POINTER
  lda (nb65_params),y
  sta tftp_filesize
  iny
  lda (nb65_params),y  
  sta tftp_filesize+1
  
  jsr tftp_download
  jmp @after_tftp_call
:

  cpy #NB65_TFTP_CALLBACK_UPLOAD
  bne :+
  jsr set_tftp_params
  jsr set_tftp_callback_vector
  jmp tftp_upload
:

  cpy #NB65_PRINT_ASCIIZ
  bne :+
  jsr print
  clc
  rts
:  

  cpy #NB65_PRINT_HEX
  bne :+
  jsr print_hex
  clc
  rts
:  

  cpy #NB65_PRINT_DOTTED_QUAD
  bne :+
  jsr print_dotted_quad
  clc
  rts
:  

  cpy #NB65_PRINT_IP_CONFIG
  bne :+
  jsr print_ip_config
  clc
  rts
:

;these are the API "version 2" functions

.ifdef API_VERSION
.if (API_VERSION>1)

  .segment "TCP_VARS"
    port_number: .res 2
    nonzero_octets: .res 1
  .code

  cpy #NB65_DOWNLOAD_RESOURCE
  bne :+  
.import url_download
.import url_download_buffer
.import url_download_buffer_length


  ldy #NB65_URL_DOWNLOAD_BUFFER
  lda (nb65_params),y
  sta url_download_buffer
  iny
  lda (nb65_params),y
  sta url_download_buffer+1

  ldy #NB65_URL_DOWNLOAD_BUFFER_LENGTH
  lda (nb65_params),y
  sta url_download_buffer_length
  iny
  lda (nb65_params),y
  sta url_download_buffer_length+1
  
  ldy #NB65_URL+1
  lda (nb65_params),y
  tax
  dey
  lda (nb65_params),y
  jmp url_download
:

  cpy #NB65_TCP_CONNECT
  bne :+  
  .import tcp_connect
  .import tcp_callback
  .import tcp_connect_ip
  .import tcp_listen
  ldy #3
  lda #0
  sta nonzero_octets
@copy_dest_ip:  
  lda (nb65_params),y
  beq @octet_was_zero
  inc nonzero_octets
@octet_was_zero:  
  sta tcp_connect_ip,y
  dey
  bpl @copy_dest_ip
  
  ldy #NB65_TCP_CALLBACK
  lda (nb65_params),y
  sta tcp_callback
  iny
  lda (nb65_params),y
  sta tcp_callback+1
  
  ldy #NB65_TCP_PORT+1
  lda (nb65_params),y
  tax
  dey
  lda (nb65_params),y
  ldy nonzero_octets
  bne @outbound_tcp_connection
  jmp tcp_listen
  
@outbound_tcp_connection:  
  jmp tcp_connect

:

  .import tcp_send
  .import tcp_send_data_len
  cpy #NB65_SEND_TCP_PACKET
  bne :+
  ldy #NB65_TCP_PAYLOAD_LENGTH
  lda (nb65_params),y
  sta tcp_send_data_len
  iny
  lda (nb65_params),y
  sta tcp_send_data_len+1
  ldy #NB65_TCP_PAYLOAD_POINTER+1
  lda (nb65_params),y
  tax
  dey
  lda (nb65_params),y
  jmp tcp_send

:


.import tcp_close
  cpy #NB65_TCP_CLOSE_CONNECTION
  bne :+
  jmp tcp_close
:


.import filter_dns
.import get_filtered_input
.import filter_number

  cpy #NB65_INPUT_STRING
  bne :+
  ldy #40 ;max chars
  ldax #$0000
  jmp get_filtered_input
:

  cpy #NB65_INPUT_HOSTNAME  
  bne :+
  ldy #40 ;max chars
  ldax #filter_dns
  jmp get_filtered_input
:

cpy #NB65_INPUT_PORT_NUMBER
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

cpy #NB65_BLOCK_COPY
  bne :+
  ;this is where we pay the price for trying to save a few 'zero page' pointers 
  ;by reusing the 'copy_src' and 'copy_dest' addresses!
.segment "TCP_VARS"
  tmp_copy_src: .res 2
  tmp_copy_dest: .res 2
  tmp_copy_length: .res 2
.code
  
  ldy #NB65_BLOCK_SRC
  lda (nb65_params),y
  sta tmp_copy_src
  iny  
  lda (nb65_params),y
  sta tmp_copy_src+1
  
  ldy #NB65_BLOCK_DEST
  lda (nb65_params),y
  sta tmp_copy_dest
  iny  
  lda (nb65_params),y
  sta tmp_copy_dest+1

  ldy #NB65_BLOCK_SIZE
  lda (nb65_params),y
  sta tmp_copy_length
  iny  
  lda (nb65_params),y
  sta tmp_copy_length+1

  ldax tmp_copy_src
  stax  copy_src
  ldax tmp_copy_dest
  stax  copy_dest
  ldax tmp_copy_length
  jmp copymem
:
.endif
.endif

  cpy #NB65_GET_LAST_ERROR
  bne :+
  lda ip65_error
  clc
  rts
:  


;default function handler
  lda #NB65_ERROR_FUNCTION_NOT_SUPPORTED
  sta ip65_error
  sec        ;carry flag set = error
  rts