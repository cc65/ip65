.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif

 .export print_hex
 .export print_ip_config
 .export dhcp_msg
 .export ok_msg
 .export failed_msg
 .export init_msg
 .export print
 .export print_decimal
 .export print_dotted_quad
 .export print_arp_cache
 .export mac_address_msg
 .export ip_address_msg
 .export netmask_msg
 .export gateway_msg
 .export dns_server_msg
 .export tftp_server_msg
 .import ip65_error
 .export print_errorcode

 .import arp_cache
 .importzp ac_size
  
.import cs_driver_name
.importzp copy_src
.import cfg_tftp_server
;reuse the copy_src zero page var
pptr = copy_src

.bss
temp_bin: .res 1
temp_bcd: .res 2
temp_ptr: .res 2
.code
.macro print_driver_init
  ldax #cs_driver_name
  jsr print
  ldax #init_msg
	jsr print
.endmacro


.macro print_dhcp_init
  ldax #dhcp_msg
  jsr print
  ldax #init_msg
	jsr print
.endmacro

.macro print_failed
  ldax #failed_msg
	jsr print
  jsr print_cr
.endmacro

.macro print_ok
  ldax #ok_msg
	jsr print
  jsr print_cr
.endmacro


.code

.import print_a
.import print_cr
.import cs_driver_name
print_ip_config:

  ldax #interface_type
  jsr print

  ldax #cs_driver_name
  jsr print
  jsr print_cr
  
  ldax #mac_address_msg
  jsr print
  jsr cfg_get_configuration_ptr ;ax=base config, carry flag clear
  ;first 6 bytes of cfg_get_configuration_ptr is MAC address
  jsr print_mac
  jsr print_cr

  ldax #ip_address_msg
  jsr print
  jsr cfg_get_configuration_ptr ;ax=base config, carry flag clear
  adc #NB65_CFG_IP
  bcc :+
  inx
:  
  jsr print_dotted_quad
  jsr print_cr

  ldax #netmask_msg
  jsr print
   jsr cfg_get_configuration_ptr ;ax=base config, carry flag clear
  adc #NB65_CFG_NETMASK
  bcc :+
  inx
: 
  jsr print_dotted_quad
  jsr print_cr

  ldax #gateway_msg
  jsr print
  jsr cfg_get_configuration_ptr ;ax=base config, carry flag clear
  adc #NB65_CFG_GATEWAY
  bcc :+
  inx
:
  jsr print_dotted_quad
  jsr print_cr

  ldax #dns_server_msg
  jsr print
  jsr cfg_get_configuration_ptr ;ax=base config, carry flag clear
  adc #NB65_CFG_DNS_SERVER
  bcc :+
  inx
:  jsr print_dotted_quad
  jsr print_cr

  ldax #tftp_server_msg
  jsr print
  ldax #cfg_tftp_server
  jsr print_dotted_quad
  jsr print_cr

  ldax #dhcp_server_msg
  jsr print
  jsr cfg_get_configuration_ptr ;ax=base config, carry flag clear
  adc #NB65_CFG_DHCP_SERVER
  bcc :+
  inx
:
  jsr print_dotted_quad
  jsr print_cr

  rts
  
  
print:
	sta pptr
	stx pptr + 1
	
@print_loop:
  ldy #0
  lda (pptr),y
	beq @done_print
	jsr print_a
	inc pptr
	bne @print_loop
  inc pptr+1
  bne @print_loop ;if we ever get to $ffff, we've probably gone far enough ;-)
@done_print:
  rts

print_arp_cache:
  ldax #arp_cache_header
  jsr print
	ldax #arp_cache
	stax temp_ptr  
	lda #ac_size    
@print_one_arp_entry:
  pha
  lda #'$'
  jsr print_a
  lda temp_ptr+1
  jsr print_hex
  lda temp_ptr
  jsr print_hex
  lda #' '
  jsr print_a
  
	ldax temp_ptr  
  jsr print_mac
  lda #' '
  jsr print_a
  ldax temp_ptr
	clc
  adc #6
	bcc :+
	inx
:  
  stax temp_ptr
  jsr print_dotted_quad
  ldax temp_ptr
	clc
  adc #4
	bcc :+
	inx
: 
  stax temp_ptr
  jsr print_cr
  pla
  sec
  sbc #1
  
	bne @print_one_arp_entry
  clc
	rts


;print the 4 bytes pointed at by AX as dotted decimals
print_dotted_quad:
  sta pptr
	stx pptr + 1
  ldy #0
  lda (pptr),y
  jsr print_decimal 
  lda #'.'
  jsr print_a

  ldy #1
  lda (pptr),y
  jsr print_decimal 
  lda #'.'
  jsr print_a

  ldy #2
  lda (pptr),y
  jsr print_decimal 
  lda #'.'
  jsr print_a

  ldy #3
  lda (pptr),y
  jsr print_decimal
  
  rts
  
;print 6 bytes printed at by AX as a MAC address  
print_mac:
  stax pptr  
  ldy #0
@one_mac_digit:
  tya   ;just to set the Z flag
  pha
  beq @dont_print_colon
  lda #':'
  jsr print_a
@dont_print_colon:
  pla 
  tay
  lda (pptr),y
  jsr print_hex
  iny
  cpy #06
  bne @one_mac_digit
  rts
print_decimal:  ;print byte in A as a decimal number
  pha
  sta temp_bin   ;save 
  sed       ; Switch to decimal mode
  lda #0		; Ensure the result is clear
  sta temp_bcd
  sta temp_bcd+1
  ldx #8  ; The number of source bits		
  :
  asl temp_bin+0		; Shift out one bit
	lda temp_bcd+0	; And add into result
  adc temp_bcd+0
  sta temp_bcd+0
  lda temp_bcd+1	; propagating any carry
  adc temp_bcd+1
  sta temp_bcd+1
  dex		; And repeat for next bit
	bne :-
  
  cld   ;back to binary
      
  pla       ;get back the original passed in number
  bmi @print_hundreds ; if N is set, the number is >=128 so print all 3 digits
  cmp #10
  bmi @print_units
  cmp #100
  bmi @print_tens
@print_hundreds:
  lda temp_bcd+1   ;get the most significant digit
  and #$0f
  clc
  adc #'0'
  jsr print_a

@print_tens:
  lda temp_bcd
  lsr
  lsr
  lsr
  lsr
  clc
  adc #'0'
  jsr print_a
@print_units:
  lda temp_bcd
  and #$0f
  clc
  adc #'0'
  jsr print_a
  
  rts


print_hex:
  pha  
  pha  
  lsr
  lsr
  lsr
  lsr
  tax
  lda hexdigits,x
  jsr print_a
  pla
  and #$0F
  tax
  lda hexdigits,x
  jsr print_a
  pla
  rts

print_errorcode:
  ldax #error_code
  jsr print
  lda ip65_error
  jsr print_hex
  jmp print_cr

.rodata
hexdigits:
.byte "0123456789ABCDEF"

interface_type:
.byte "INTERFACE   : ",0

mac_address_msg:
.byte "MAC ADDRESS : ", 0

ip_address_msg:
.byte "IP ADDRESS  : ", 0

netmask_msg:
.byte "NETMASK     : ", 0

gateway_msg:
.byte "GATEWAY     : ", 0
  
dns_server_msg:
.byte "DNS SERVER  : ", 0

dhcp_server_msg:
.byte "DHCP SERVER : ", 0

tftp_server_msg:
.byte "TFTP SERVER : ", 0

dhcp_msg:
  .byte "DHCP",0

init_msg:
  .byte " INITIALIZING ",0

arp_cache_header:
  .byte " MEM          MAC         IP",13,0

failed_msg:
	.byte "FAILED", 0

ok_msg:
	.byte "OK", 0
 
dns_lookup_failed_msg:
 .byte "DNS LOOKUP FAILED", 0

error_code:  
  .asciiz "ERROR CODE: "

