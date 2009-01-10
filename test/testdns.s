  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  
  .import dns_set_hostname
  .import dns_resolve
  .import dns_ip
  .import dns_status

	.bss

temp_bin: .res 1
temp_bcd: .res 2


	.segment "STARTUP"

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


	.code

init:
    
 jsr print_ip_config
 
 init_ip_via_dhcp 
 
;  jsr overwrite_with_hardcoded_dns_server
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

  rts

do_dns_query:
  pha
  jsr print
  lda #' '
  jsr $ffd2
  lda #':'
  jsr $ffd2
  lda #' '
  jsr $ffd2
  pla
  jsr dns_set_hostname
  jsr dns_resolve
  bcc :+
  ldax #dns_lookup_failed_msg
  jsr print
  jmp @print_dns_status
:  
  ldax #dns_ip
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
:
  lda hardcoded_dns_server,x
  sta cfg_dns,x
  dex
  bpl :-
  rts



	.rodata


hostname_1:
  .byte "SLASHDOT.ORG",0          ;this should be an A record

hostname_2:
  .byte "VICTA.JAMTRONIX.COM",0   ;this should be a CNAME

hostname_3:
  .byte "WWW.JAMTRONIX.COM",0     ;this should be another CNAME

hostname_4:
  .byte "FOO.BAR.BOGUS",0         ;this should fail

hostname_5:                       ;this currently fails, would be nice if we noticed it was an IP address
  .byte "111.22.3.4",0

hostname_6:                       ;make sure doesn't get treated as a number
  .byte "3COM.COM",0

hardcoded_dns_server:
;.byte 61,9,195,193 
;.byte 64,127,100,12
.byte 205,171,3,65
.byte 69,111,95,106 
