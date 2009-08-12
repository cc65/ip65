;routine for parsing a URL


.include "../inc/common.i"

.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif

.import output_buffer
.importzp copy_src
.importzp copy_dest

.import parser_init
.import parser_skip_next
.import dns_set_hostname
.import dns_resolve
.import parse_integer
.import dns_ip
.export  url_ip
.export  url_port
.export  url_selector
.export url_resource_type

target_string=copy_src
search_string=copy_dest
selector_buffer=output_buffer

.bss
  url_string: .res 2 
  url_ip: .res 4    ;will be set with ip address of host in url
  url_port: .res 2 ;will be set with port number of url
  url_selector: .res 2 ;will be set with address of selector part of URL
  url_type: .res 1
  url_resource_type: .res 1
  url_type_unknown=0
  url_type_gopher=1
  url_type_http=2
  
  src_ptr: .res 1
  dest_ptr: .res 1
.code


;parses a URL into a form that makes it easy to retrieve the specified resource
;inputs: 
;AX = address of URL string
;outputs:
; sec if a malformed url, otherwise:
; url_ip = ip address of host in url
; url_port = port number of url
; url_selector= address of selector part of URL
url_parse:
  stax url_string
  ldy #0
  sty url_type
  sty url_port
  sty url_port+1
  sty url_resource_type

  jsr skip_to_hostname
  bcc :+
  ldax url_string
  jmp @no_protocol_specifier
:  
  ldax url_string
  stax  search_string

  lda (search_string),y
  cmp  #'g'
  beq @gopher
  cmp  #'G'
  beq @gopher
  cmp  #'h'
  beq @http
  cmp  #'H'
  beq @http
@exit_with_error:  
  lda #NB65_MALFORMED_URL
  sta ip65_error
@exit_with_sec:  
  sec
  rts
@http:
  lda #url_type_http
  sta url_type
  lda #80
  sta url_port
  jmp @protocol_set
@gopher:
lda #url_type_gopher
  sta url_type
  lda #70
  sta url_port
@protocol_set:
  jsr skip_to_hostname
  ;now pointing at hostname
  bcs @exit_with_error
@no_protocol_specifier:  
  jsr dns_set_hostname
  bcs @exit_with_sec
  jsr dns_resolve
  bcs @exit_with_sec
  ;copy IP address
  ldx #3
:
  lda dns_ip,x
  sta url_ip,x
  dex
  bpl :-

  jsr skip_to_hostname
  
  ;skip over next colon
  ldax #colon
  jsr parser_skip_next
  bcs @no_port_in_url
  ;AX now point at first thing past a colon - should be a number:
  jsr  parse_integer
  stax url_port
@no_port_in_url:  
  ;skip over next slash
  ldax #slash
  jsr parser_skip_next
  ;AX now pointing at selector
  stax copy_src
  ldax #selector_buffer
  stax copy_dest
  lda #0
  sta src_ptr
  sta dest_ptr
  lda url_type
  
  cmp #url_type_gopher
  bne @not_gopher  
  ;first byte after / in a gopher url is the resource type  
  ldy src_ptr  
  lda (copy_src),y
  sta url_resource_type
  inc src_ptr  
  jmp @start_of_selector
@not_gopher:  
  cmp #url_type_http
  bne @done ; if it's not gopher or http, we don't know how to build a selector
  ldy #3
  sty dest_ptr
:
  lda get,y
  sta (copy_dest),y
  dey
  bpl :-  
@start_of_selector: 
  lda #'/'
  inc dest_ptr  
  jmp @save_first_byte_of_selector
@copy_one_byte:
  ldy src_ptr  
  lda (copy_src),y
  beq @end_of_selector
  inc src_ptr  
@save_first_byte_of_selector:  
  ldy dest_ptr  
  sta (copy_dest),y  
  inc dest_ptr
  bne @copy_one_byte
@end_of_selector:
  ldy dest_ptr
  lda #$0d
  sta (copy_dest),y
  iny
  lda #$0a
  sta (copy_dest),y
  iny
@done:  
  lda #$00
  sta (copy_dest),y
  ldax #selector_buffer
  clc
  rts
  
skip_to_hostname:
  ldax url_string
  jsr parser_init
  ldax #colon_slash_slash
  jmp parser_skip_next
  
  get: .byte "GET "
  colon_slash_slash: .byte ":/"
  slash: .byte "/",0
  colon: .byte ":",0