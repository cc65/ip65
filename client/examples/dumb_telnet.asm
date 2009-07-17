;NB65 API example in DASM format (http://www.atari2600.org/DASM/)
  processor 6502

  include "../inc/nb65_constants.i"

  ;useful macros 
  mac     ldax
    lda     [{1}]
    ldx     [{1}]+1
  endm

  mac     ldaxi
    lda     #<[{1}]
    ldx     #>[{1}]
  endm

  mac     stax
    sta     [{1}]
    stx     [{1}]+1
  endm

  mac cout
    lda [{1}]
    jsr print_a
  endm   

  mac print_cr
    cout #13
    jsr print_a
  endm

  mac nb65call
    ldy [{1}]
    jsr NB65_DISPATCH_VECTOR   
  endm

  mac print
    
    ldaxi [{1}]
    ldy #NB65_PRINT_ASCIIZ
    jsr NB65_DISPATCH_VECTOR   
  endm


;some routines & zero page variables
print_a equ $ffd2
temp_ptr equ $FB ; scratch space in page zero


;start of code
;NO BASIC stub! needs to be direct booted via TFTP
  org $1000
    
  ldaxi #NB65_CART_SIGNATURE  ;where signature should be in cartridge (if cart is banked in)
  jsr  look_for_signature
  bcc found_nb65_signature

  ldaxi #NB65_RAM_STUB_SIGNATURE  ;where signature should be in a RAM stub
  jsr  look_for_signature
  bcs nb65_signature_not_found
  jsr NB65_RAM_STUB_ACTIVATE     ;we need to turn on NB65 cartridge
  jmp found_nb65_signature
  
nb65_signature_not_found
  ldaxi #nb65_api_not_found_message
  jsr print_ax
  rts

found_nb65_signature

  lda NB65_API_VERSION
  cmp #02
  bpl .version_ok
  print incorrect_version
  jmp reset_after_keypress    
.version_ok  
  print #initializing
  nb65call #NB65_INITIALIZE
	bcc .init_ok
  print_cr
  print #failed
  print_cr
  jsr print_errorcode
  jmp reset_after_keypress    
.init_ok

;if we got here, we have found the NB65 API and initialised the IP stack
;print out the current configuration
  nb65call #NB65_PRINT_IP_CONFIG
;prompt for a hostname, then resolve to an IP address
.get_hostname  
  print #remote_host
  nb65call #NB65_INPUT_HOSTNAME
  bcc .host_entered
  ;if no host entered, then bail.
  jmp reset_after_keypress
.host_entered
  stax nb65_param_buffer
  print_cr
  print #resolving
  ldax nb65_param_buffer
  nb65call #NB65_PRINT_ASCIIZ
  print_cr
  ldaxi #nb65_param_buffer
  nb65call #NB65_DNS_RESOLVE
  bcc .resolved_ok
  print #failed
  print_cr
  jsr print_errorcode
  jmp .get_hostname
.resolved_ok  
.get_port
  print #remote_port
  nb65call #NB65_INPUT_PORT_NUMBER
  bcc .port_entered
  ;if no port entered, then assume port 23
  ldaxi #23
.port_entered    
  stax nb65_param_buffer+NB65_TCP_PORT
  print_cr
  
  print #char_mode_prompt
.char_mode_input
  jsr $ffe4
  cmp #"A"
  beq .ascii_mode
  cmp #"a"
  beq .ascii_mode

  cmp #"P"
  beq .petscii_mode
  cmp #"p"
  beq .petscii_mode
  jmp .char_mode_input
.ascii_mode
  lda #0
  jmp .character_mode_set
.petscii_mode  
  lda #1
.character_mode_set  
  sta character_mode
  
  ldaxi #tcp_callback
  stax nb65_param_buffer+NB65_TCP_CALLBACK
  print #connecting
  ldaxi  #nb65_param_buffer
  nb65call  #NB65_TCP_CONNECT
  bcc .connect_ok 
  print_cr
  print #failed
  jsr print_errorcode
  jmp .get_hostname
.connect_ok 
  print #ok
  print_cr
  lda #0
  sta connection_closed
.main_polling_loop
  jsr NB65_PERIODIC_PROCESSING_VECTOR
  lda connection_closed
  beq .not_disconnected
  print #disconnected
  jmp .get_hostname
.not_disconnected  
  ;is there anything in the input buffer?
  lda $c6 ;NDX - chars in keyboard buffer
  beq .main_polling_loop
  tay
  dey 
  ldx #0
  stax nb65_param_buffer+NB65_TCP_PAYLOAD_LENGTH
  ldaxi #output_buffer
  stax nb65_param_buffer+NB65_TCP_PAYLOAD_POINTER
.copy_char_from_KEYD  
  lda $277,y  ;read direct from keyboard buffer
  tax 
  lda character_mode
  bne .no_conversion_required
  lda petscii_to_ascii_table,x
  tax
.no_conversion_required
  txa
  sta output_buffer,y
  dey
  bne .copy_char_from_KEYD
  sty $c6 ;set length of keyboard buffer back to 0
  ldaxi  #nb65_param_buffer
  nb65call  #NB65_SEND_TCP_PACKET
  bcs .error_on_send
  jmp .main_polling_loop

.error_on_send
  print #transmission_error
  jsr print_errorcode
  jmp .get_hostname

;tcp callback - will be executed whenever data arrives on the TCP connection
tcp_callback
  ldaxi #nb65_param_buffer
  nb65call #NB65_GET_INPUT_PACKET_INFO
  
  lda nb65_param_buffer+NB65_PAYLOAD_LENGTH+1
  cmp #$ff
  bne .not_eof
  lda #1
  sta connection_closed
  rts
.not_eof
  
  ldax nb65_param_buffer+NB65_PAYLOAD_POINTER
  stax temp_ptr
  ldx nb65_param_buffer+NB65_PAYLOAD_LENGTH ;assumes length of inbound data  is < 255
  ldy #0
.next_byte
  lda (temp_ptr),y
  jsr print_a
  iny
  dex
  bpl .next_byte

  print_cr

  
  rts

;look for NB65 signature at location pointed at by AX
look_for_signature subroutine
  stax temp_ptr
  ldy #3
.check_one_byte
  lda (temp_ptr),y
  cmp nb65_signature,y
  bne .bad_match  
  dey 
  bpl .check_one_byte  
  clc
  rts
.bad_match
  sec
  rts

print_ax subroutine
  stax temp_ptr
  ldy #0
.next_char 
  lda (temp_ptr),y
  beq .done
  jsr print_a
  iny
  jmp .next_char
.done
  rts
  
get_key
  jsr $ffe4
  cmp #0
  beq get_key
  rts

reset_after_keypress
  print  #press_a_key_to_continue    
  jsr get_key
  jmp $fce2   ;do a cold start


print_errorcode
  print #error_code
  nb65call #NB65_GET_LAST_ERROR
  nb65call #NB65_PRINT_HEX
  print_cr
  rts

  

;constants
nb65_api_not_found_message dc.b "ERROR - NB65 API NOT FOUND.",13,0
incorrect_version dc.b "ERROR - NB65 API MUST BE AT LEAST VERSION 2.",13,0

nb65_signature dc.b $4E,$42,$36,$35  ; "NB65"  - API signature
initializing dc.b "INITIALIZING ",13,0
error_code dc.b "ERROR CODE: $",0
resolving dc.b "RESOLVING ",0
connecting dc.b "CONNECTING ",0
disconnected dc.b 13,"CONNECTION CLOSED",13,0
remote_host dc.b "REMOTE HOST - BLANK TO QUIT",13,": ",0
remote_port dc.b "REMOTE PORT - BLANK FOR TELNET DEFAULT",13,": ",0
char_mode_prompt dc.b "CHARACTER MODE - A=ASCII, P=PETSCII",13,": ",0
press_a_key_to_continue dc.b "PRESS A KEY TO CONTINUE",13,0
failed dc.b "FAILED ", 0
ok dc.b "OK ", 0
transmission_error dc.b "ERROR WHILE SENDING ",0
ascii_to_petscii_table
  dc.b $00,$01,$02,$03,$04,$05,$06,$07,$14,$09,$0d,$11,$93,$0a,$0e,$0f
  dc.b $10,$0b,$12,$13,$08,$15,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f
  dc.b $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f
  dc.b $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f
  dc.b $40,$c1,$c2,$c3,$c4,$c5,$c6,$c7,$c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf
  dc.b $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$da,$5b,$5c,$5d,$5e,$5f
  dc.b $c0,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f
  dc.b $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$db,$dc,$dd,$de,$df
  dc.b $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8a,$8b,$8c,$8d,$8e,$8f
  dc.b $90,$91,$92,$0c,$94,$95,$96,$97,$98,$99,$9a,$9b,$9c,$9d,$9e,$9f
  dc.b $a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab,$ac,$ad,$ae,$af
  dc.b $b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9,$ba,$bb,$bc,$bd,$be,$bf
  dc.b $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f
  dc.b $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$7b,$7c,$7d,$7e,$7f
  dc.b $e0,$e1,$e2,$e3,$e4,$e5,$e6,$e7,$e8,$e9,$ea,$eb,$ec,$ed,$ee,$ef
  dc.b $f0,$f1,$f2,$f3,$f4,$f5,$f6,$f7,$f8,$f9,$fa,$fb,$fc,$fd,$fe,$ff

petscii_to_ascii_table
  dc.b $00,$01,$02,$03,$04,$05,$06,$07,$14,$09,$0d,$11,$93,$0a,$0e,$0f
  dc.b $10,$0b,$12,$13,$08,$15,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f
  dc.b $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f
  dc.b $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f
  dc.b $40,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f
  dc.b $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$5b,$5c,$5d,$5e,$5f
  dc.b $c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7,$c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf
  dc.b $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$da,$db,$dc,$dd,$de,$df
  dc.b $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8a,$8b,$8c,$8d,$8e,$8f
  dc.b $90,$91,$92,$0c,$94,$95,$96,$97,$98,$99,$9a,$9b,$9c,$9d,$9e,$9f
  dc.b $a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab,$ac,$ad,$ae,$af
  dc.b $b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9,$ba,$bb,$bc,$bd,$be,$bf
  dc.b $60,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f
  dc.b $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$7b,$7c,$7d,$7e,$7f
  dc.b $a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab,$ac,$ad,$ae,$af
  dc.b $b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9,$ba,$bb,$bc,$bd,$be,$bf


;variables
connection_closed ds.b 1
character_mode ds.b 1
nb65_param_buffer DS.B $20  
output_buffer: DS.B $100
