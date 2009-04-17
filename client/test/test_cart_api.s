;test the "NETBOOT65 Cartridge API"
.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif

.include "../ip65/copymem.s"

; load A/X macro
	.macro ldax arg
	.if (.match (.left (1, arg), #))	; immediate mode
	lda #<(.right (.tcount (arg)-1, arg))
	ldx #>(.right (.tcount (arg)-1, arg))
	.else					; assume absolute or zero page
	lda arg
	ldx 1+(arg)
	.endif
	.endmacro

; store A/X macro
.macro stax arg
	sta arg
	stx 1+(arg)
.endmacro	

print_a = $ffd2

.macro cout arg
  lda arg
  jsr print_a
.endmacro   
    
  .zeropage
  temp_ptr:		.res 2
  
  .bss
  nb65_param_buffer: .res $20  
  block_number: .res $0
  
.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

.word basicstub		; load address

.macro print arg
  ldax arg
	ldy #NB65_PRINT_ASCIIZ
  jsr NB65_DISPATCH_VECTOR 
.endmacro 

.macro print_cr
  lda #13
	jsr print_a
.endmacro

.macro call arg
	ldy arg
  jsr NB65_DISPATCH_VECTOR   
.endmacro

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


;look for NB65 signature at location pointed at by AX
look_for_signature: 
  stax temp_ptr
  ldy #3
@check_one_byte:
  lda (temp_ptr),y
  cmp nb65_signature,y
  bne @bad_match  
  dey 
  bpl@check_one_byte  
  clc
  rts
@bad_match:
  sec
  rts
  
init:
  

  ldax #NB65_CART_SIGNATURE  ;where signature should be in cartridge
  jsr  look_for_signature
  bcc @found_nb65_signature

  ldax #NB65_RAM_STUB_SIGNATURE  ;where signature should be in RAM
  jsr  look_for_signature
  bcc :+
  jmp nb65_signature_not_found
:  
  jsr NB65_RAM_STUB_ACTIVATE     ;we need to turn on NB65 cartridge
  
@found_nb65_signature:

  print #initializing

  ldy #NB65_INITIALIZE
  jsr NB65_DISPATCH_VECTOR 
	bcc :+  
  print #failed
  jsr print_errorcode
  jmp bad_boot    
:  

  print #ok
  print_cr
  
  call #NB65_PRINT_IP_CONFIG
  
;DNS resolution test 
  
  ldax #test_hostname
  stax nb65_param_buffer+NB65_DNS_HOSTNAME

  call #NB65_PRINT_ASCIIZ  

  cout #' '
  cout #':'
  cout #' '
  
  ldax  #nb65_param_buffer
  call #NB65_DNS_RESOLVE
  bcc :+
  print #dns_lookup_failed_msg
  print_cr
  jmp print_errorcode
:  
  ldax #nb65_param_buffer+NB65_DNS_HOSTNAME_IP
  call #NB65_PRINT_DOTTED_QUAD
  print_cr


  
;tftp send test
  lda #0
  sta block_number
  lda #$FF
  ldx #$03
:
  sta nb65_param_buffer,x   ;set TFTP server as broadcast address
  dex
  bpl :-
  ldax #test_file
  stax nb65_param_buffer+NB65_TFTP_FILENAME
  ldax #tftp_upload_callback
  stax nb65_param_buffer+NB65_TFTP_POINTER
  ldax #nb65_param_buffer
  call #NB65_TFTP_CALLBACK_UPLOAD


@download_test:
;tftp download callback test
  lda #0
  sta block_number
  lda #$FF
  ldx #$03
:
  sta nb65_param_buffer,x   ;set TFTP server as broadcast address
  dex
  bpl :-
  ldax #test_file
  stax nb65_param_buffer+NB65_TFTP_FILENAME
  ldax #tftp_download_callback
  stax nb65_param_buffer+NB65_TFTP_POINTER
  ldax #nb65_param_buffer
  call #NB65_TFTP_CALLBACK_DOWNLOAD
  lda #'$'
  jsr print_a
  lda  nb65_param_buffer+NB65_TFTP_FILESIZE+1
  jsr print_hex
  lda  nb65_param_buffer+NB65_TFTP_FILESIZE
  jsr print_hex
  print #bytes_download
  print_cr
  
;udp callback test
  
  ldax  #64     ;listen on port 64
  stax nb65_param_buffer+NB65_UDP_LISTENER_PORT
  ldax  #udp_callback
  stax nb65_param_buffer+NB65_UDP_LISTENER_CALLBACK
  ldax  #nb65_param_buffer
  call   #NB65_UDP_ADD_LISTENER
	bcc :+  
  print #failed
  jsr print_errorcode
  jmp bad_boot    
:

  print #listening	
  

@loop_forever:
  jsr NB65_PERIODIC_PROCESSING_VECTOR
  jmp @loop_forever
  
  
tftp_upload_callback:
  stax copy_dest
  inc block_number
  print #sending
  print #block_no
  lda block_number
  jsr print_hex
  print_cr
  
  lda block_number
  asl
  cmp #$10
  beq @last_block
  clc
  adc #$a0
  tax
  lda #0
  stax copy_src
  ldax #$200
  jsr copymem
  ldax #$200
  rts
@last_block:  
  ldax #0
  rts

tftp_download_callback:
  inc block_number
  print #received
  print #block_no
  lda block_number
  jsr print_hex
  print_cr
  rts

udp_callback:

  ldax #nb65_param_buffer
  call #NB65_GET_INPUT_PACKET_INFO

  print #port

  lda nb65_param_buffer+NB65_LOCAL_PORT+1
  call #NB65_PRINT_HEX

  lda nb65_param_buffer+NB65_LOCAL_PORT
  call #NB65_PRINT_HEX

  print_cr

  print #received
  print #from

  ldax #nb65_param_buffer+NB65_REMOTE_IP
  call #NB65_PRINT_DOTTED_QUAD
  
  cout #' '
  
  print #port
  
  lda nb65_param_buffer+NB65_REMOTE_PORT+1
  call #NB65_PRINT_HEX  
  lda nb65_param_buffer+NB65_REMOTE_PORT
  call #NB65_PRINT_HEX
  
  print_cr
  
  print #length

  lda nb65_param_buffer+NB65_PAYLOAD_LENGTH+1
  call #NB65_PRINT_HEX
  lda nb65_param_buffer+NB65_PAYLOAD_LENGTH
  call #NB65_PRINT_HEX
  print_cr  
  print #data

  ldax nb65_param_buffer+NB65_PAYLOAD_POINTER
  
  stax temp_ptr
  ldx nb65_param_buffer+NB65_PAYLOAD_LENGTH ;assumes length is < 255
  ldy #0
:
  lda (temp_ptr),y
  jsr print_a
  iny
  dex
  bpl :-
  
  print_cr

;make and send reply
  ldax #reply_message
  stax nb65_param_buffer+NB65_PAYLOAD_POINTER

  ldax #reply_message_length
  stax nb65_param_buffer+NB65_PAYLOAD_LENGTH
 
  ldax #nb65_param_buffer
  call #NB65_SEND_UDP_PACKET  
  bcc :+
  jmp print_errorcode
:
  print #reply_sent
  rts
  
bad_boot:
  print  #press_a_key_to_continue
restart:    
  jsr get_key
  jmp $fce2   ;do a cold start


print_errorcode:
  print #error_code
  call #NB65_GET_LAST_ERROR
  call #NB65_PRINT_HEX
  print_cr
  rts

nb65_signature_not_found:

  ldy #0
:
  lda nb65_signature_not_found_message,y
  beq restart
  jsr print_a
  iny
  jmp :-
  

;use C64 Kernel ROM function to read a key
;inputs: none
;outputs: A contains ASCII value of key just pressed
get_key:
  jsr $ffe4
  cmp #0
  beq get_key
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

.rodata
hexdigits:
.byte "0123456789ABCDEF"

test_hostname:
  .byte "RETROHACKERS.COM",0          ;this should be an A record

  received:  
  .asciiz "RECEIVED "
  sending: 
  .asciiz "SENDING "
  from:  
  .asciiz " FROM: "
  
listening:  
  .byte "LISTENING ON UDP PORT 64",13,0


reply_sent:  
  .byte "REPLY SENT.",13,0


initializing:  
  .byte "INITIALIZING ",0

port:  
  .byte "PORT: $",0

length:  
  .byte "LENGTH: $",0
  
data:
  .byte "DATA: ",0

block_no:  
  .byte "BLOCK: $",0

error_code:  
  .asciiz "ERROR CODE: $"
press_a_key_to_continue:
  .byte "PRESS A KEY TO CONTINUE",13,0

failed:
	.byte "FAILED ", 0

ok:
	.byte "OK ", 0
 
 nb65_signature_not_found_message:
 .byte "NO NB65 API FOUND",13,"PRESS ANY KEY TO RESET", 0
 
dns_lookup_failed_msg:
 .byte "DNS LOOKUP FAILED", 0

bytes_download: .byte "BYTES DOWNLOADED",13,0

reply_message:
  .byte "PONG!"
reply_message_end:
reply_message_length=reply_message_end-reply_message

test_file:
.byte "TESTFILE.BIN",0

nb65_signature:
  .byte $4E,$42,$36,$35  ; "NB65"  - API signature