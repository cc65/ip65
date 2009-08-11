.include "../inc/common.i"
.include "../inc/commonprint.i"
.include "../ip65/url.s"
.include "../inc/net.i"

.import print_a
.import get_key
.import cfg_get_configuration_ptr
.import ascii_to_native
.import parser_init
.import parser_skip_next
.importzp copy_src
.importzp copy_dest


temp_buff=copy_dest

.bss

string_offset: .res 1
selector_ptr: .res 2
temp_url_ptr: .res 2
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

init:

  ;switch to lower case charset
  lda #23
  sta $d018

  init_ip_via_dhcp 
  jsr print_ip_config

  ldax #url_1
  jsr test_url_parse 
  ldax #url_2
  jsr test_url_parse 
  ldax #url_3
  jsr test_url_parse 
  ldax #url_4
  jsr test_url_parse 
  ldax #url_5
  jsr test_url_parse 
  ldax #url_6
  jsr test_url_parse 
  ldax #url_7
  jsr test_url_parse 
  ldax #url_8
  jsr test_url_parse 
  ldax #url_9
  jsr test_url_parse 
  ldax #url_a
  jsr test_url_parse 
  ldax #url_b
  jsr test_url_parse 
  ldax #url_c
  jsr test_url_parse 
  
  rts
  

  ldax #atom_file
  jsr parser_init
  
  ldax #entry
  jsr parser_skip_next
  bcs @done
  
@next_title:  
  ldax #title
  jsr parser_skip_next
  bcs @done
  
  jsr print_tag_contents
  jsr print_cr
  
;  jmp @next_title
@done:
  rts
test_url_parse:
  stax temp_url_ptr
  ldax #parsing
  jsr print
  ldax temp_url_ptr
  jsr print
  jsr print_cr
  ldax temp_url_ptr
  jsr url_parse
  bcc :+
  jmp print_errorcode
  :
  stax selector_ptr
  jmp print_parsed_url

print_tag_contents:
  stax temp_buff
  lda #0
  sta string_offset
@next_byte:  
  ldy string_offset
  lda (temp_buff),y
  beq @done
  cmp #'<'
  beq @done
  jsr ascii_to_native
  jsr print_a  
  inc string_offset
  beq @done  
  jmp @next_byte
@done:
  rts

print_parsed_url:
  ldax #ip
  jsr print
  ldax #url_ip
  jsr print_dotted_quad
  ldax #port
  jsr print
  lda url_port+1
  jsr print_hex
  lda url_port
  jsr print_hex
  jsr print_cr
  ldax #selector
  jsr  print
  ldax selector_ptr
  jsr print
  jmp print_cr
  
.data

entry: 
.byte "<entry>",0
title: 
.byte "<title>",0

url_1: 
.byte "http://www.jamtronix.com/",0

url_2: 
.byte "http://www.jamtronix.com/goober",0

url_3: 
.byte "http://www.jamtronix.com:8080/foo",0

url_4: 
.byte "gopher://gopher.floodgap.com/",0

url_5: 
.byte "gopher://gopher.floodgap.com/goober",0

url_6: 
.byte "gopher://gopher.floodgap.com:7070/goober",0

url_7: 
.byte "www.jamtronix.com",0

url_8: 
.byte "jamtronix.com:70",0

url_9: 
.byte "gopher.floodgap.com",0

url_a: 
.byte "gopher.floodgap.com:70",0

url_b: 
.byte "gopher.floodgap.com:80",0

url_c: 
.byte "gopher.floodgap.com:70",0


parsing: .asciiz "PARSING "
ip: .asciiz "IP: "
port: .asciiz " PORT: $"
selector: .asciiz "SELECTOR: "

atom_file:
;.incbin "atom_test.xml"


.byte 0