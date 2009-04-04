;test the "NETBOOT65 Cartridge API"
 .include "../inc/nb65_constants.i"
 .include "../inc/common.i"
 .include "../inc/commonprint.i"

  .import get_key
  .bss
  nb65_param_buffer: .res $10  

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
  
  jsr print_cr
  jsr print_ip_config
 
  ldy #NB65_INIT_IP
  jsr NB65_DISPATCH_VECTOR 
	bcc :+  
  print_failed
  jsr print_errorcode
  jmp bad_boot    
:
  
  ldy #NB65_INIT_DHCP
  jsr NB65_DISPATCH_VECTOR 

	bcc :+  
  print_failed
  jsr print_errorcode
  jmp bad_boot    
:
 
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


  
  
  
  ldax  #64
  stax nb65_param_buffer+NB65_UDP_LISTENER_PORT
  ldax  #udp_callback
  stax nb65_param_buffer+NB65_UDP_LISTENER_CALLBACK
  ldy   #NB65_UDP_ADD_LISTENER
  jsr NB65_DISPATCH_VECTOR 
	bcc :+  
  print_failed
  jsr print_errorcode
  jmp bad_boot    
:
@loop_forever:
  jsr NB65_PERIODIC_PROCESSING_VECTOR
  jmp @loop_forever
  
  jmp $a7ae  ;exit to basic
  
udp_callback:
  lda #'*'
  jmp print_a
  
do_dns_query: ;AX points at the hostname on entry 
  stax nb65_param_buffer+NB65_DNS_HOSTNAME

  jsr print
  

  pha
  jsr print
  lda #' '
  jsr print_a
  lda #':'
  jsr print_a
  lda #' '
  jsr print_a
  pla
  ldax  #nb65_param_buffer
  ldy #NB65_DNS_RESOLVE_HOSTNAME
  jsr NB65_DISPATCH_VECTOR 
  bcc :+
  ldax #dns_lookup_failed_msg
  jsr print
  jsr print_cr
  jmp print_errorcode
:  
  ldax #nb65_param_buffer+NB65_DNS_HOSTNAME_IP
  jsr print_dotted_quad  
  jsr print_cr
  rts

bad_boot:
  ldax  #press_a_key_to_continue
  jsr print
  jsr get_key
  jmp $fe66   ;do a wam start


print_errorcode:
  ldax #error_code
  jsr print
  ldy #NB65_GET_LAST_ERROR
  jsr NB65_DISPATCH_VECTOR
  jsr print_hex
  jmp print_cr

cfg_get_configuration_ptr:
  ldy #NB65_GET_IP_CONFIG_PTR
  jmp NB65_DISPATCH_VECTOR 

	.rodata

buffer1: .res 256
hostname_1:
  .byte "SLASHDOT.ORG",0          ;this should be an A record

hostname_2:
  .byte "VICTA.JAMTRONIX.COM",0   ;this should be a CNAME

hostname_3:
  .byte "FOO.BAR.BOGUS",0         ;this should fail

hostname_4:                       ;this should work (without hitting dns)
  .byte "111.22.3.4",0

hostname_5:                       ;make sure doesn't get treated as a number
  .byte "3COM.COM",0

hostname_6:
  .repeat 200
  .byte 'X'
  .endrepeat
  .byte 0     ;this should generate an error as it is too long

error_code:  
  .asciiz "ERROR CODE: "
press_a_key_to_continue:
  .byte "PRESS A KEY TO CONTINUE",13,0
