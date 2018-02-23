.include "../inc/common.inc"

.export _httpd_start
.export _httpd_send_response

.import httpd_start
.import httpd_port_number
.import httpd_send_response
.import httpd_response_buffer_length
.import tcp_remote_ip
.import http_get_value

.import pushax, pusheax, popax, popa
.importzp sreg


.data

callback:
  ldax tcp_remote_ip+2
  stax sreg
  ldax tcp_remote_ip
  jsr pusheax
  lda #$01
  jsr http_get_value
  jsr pushax
  lda #$02
  jsr http_get_value
jmpvector:
  jsr $ffff
  sec
  rts


.code

_httpd_start:
  stax jmpvector+1
  jsr popax
  stax httpd_port_number
  ldax #callback
  jmp httpd_start

_httpd_send_response:
  stax httpd_response_buffer_length
  jsr popax
  pha
  jsr popa
  tay
  pla
  cpy #$04
  bcc :+
  lda #$00
  sta httpd_response_buffer_length
  sta httpd_response_buffer_length+1
: jmp httpd_send_response
