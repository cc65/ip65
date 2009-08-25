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



protocol_http equ $00
protocol_gopher equ $01

;some routines & zero page variables
print_a   equ $ffd2
temp_ptr  equ $FB ; scratch space in page zero


;start of code
;NO BASIC stub! needs to be direct booted via TFTP
  org $1000
  
  jsr init_tod  
  
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

  

listen_on_port_80

 ldaxi #scratch_buffer
 stax tcp_buffer_ptr
 print #waiting
 ldaxi #80 ;port number
 stax nb65_param_buffer+NB65_TCP_PORT
 stx nb65_param_buffer+NB65_TCP_REMOTE_IP
 stx nb65_param_buffer+NB65_TCP_REMOTE_IP+1
 stx nb65_param_buffer+NB65_TCP_REMOTE_IP+2
 stx nb65_param_buffer+NB65_TCP_REMOTE_IP+3
 ldaxi #http_callback
 stax nb65_param_buffer+NB65_TCP_CALLBACK
 ldaxi #nb65_param_buffer 
 nb65call #NB65_TCP_CONNECT ;wait for inbound connect
 bcc  .connected_ok
 print  #error_while_waiting
 jsr  print_errorcode
 jmp reset_after_keypress    
.connected_ok
  print #ok
  lda #0
  sta connection_closed
  sta found_eol
  clc
  lda $dc09  ;time of day clock: seconds (in BCD)
  sed
  adc #$30
  cmp #$60
  bcc .timeout_set
  sec
  sbc #$60
.timeout_set:  
  cld
  sta connection_timeout_seconds
  
.main_polling_loop
  jsr NB65_PERIODIC_PROCESSING_VECTOR
  
  lda found_eol
  bne .got_eol

  lda $dc09  ;time of day clock: seconds
  
  cmp connection_timeout_seconds  
  beq .connection_timed_out
;  nb65call #NB65_PRINT_HEX
  lda connection_closed
  beq  .main_polling_loop  
  jmp listen_on_port_80
  
.connection_timed_out:
  print #timeout
  jmp listen_on_port_80
.got_eol:
  ;if we have a CR, we have got enough of a request to know if it's a HTTP or gopher request
  lda #"G"
  cmp scratch_buffer
  bne .gopher
  lda #"E"
  cmp scratch_buffer+1
  bne .gopher
  lda #"T"
  cmp scratch_buffer+2
  bne .gopher
  lda #" "
  cmp scratch_buffer+3
  bne .gopher
  lda #protocol_http
  sta protocol
  print #http
  ldx #4
  jmp .copy_selector
.gopher
  jsr  print_a
  lda #protocol_gopher
  sta protocol
  print #gopher
  ldx #0
.copy_selector:
  lda scratch_buffer,x
  cmp #"/"
  bne .copy_one_char
  inx
.copy_one_char
  lda scratch_buffer,x
  cmp #$20  
  bcc .last_char_in_selector  
  sta selector,y
  inx
  iny
  bne .copy_one_char

.last_char_in_selector  
  lda #0
  sta selector,y

  print #selector
  
;  ldaxi #html_length
  stax nb65_param_buffer+NB65_TCP_PAYLOAD_LENGTH
;  ldaxi #html
  stax nb65_param_buffer+NB65_TCP_PAYLOAD_POINTER
  ldaxi  #nb65_param_buffer
  nb65call  #NB65_SEND_TCP_PACKET

  nb65call #NB65_TCP_CLOSE_CONNECTION  
.start_new_connection   
  jmp listen_on_port_80
  




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


;init the Time-Of-Day clock - cribbed from http://codebase64.org/doku.php?id=base:initialize_tod_clock_on_all_platforms
init_tod:
	sei
	lda	#0
	sta	$d011		;Turn off display to disable badlines
	sta	$dc0e		;Set TOD Clock Frequency to 60Hz
	sta	$dc0f		;Enable Set-TOD-Clock
	sta	$dc0b		;Set TOD-Clock to 0 (hours)
	sta	$dc0a		;- (minutes)
	sta	$dc09		;- (seconds)
	sta	$dc08		;- (deciseconds)

	lda	$dc08		;
.wait_raster	
  cmp	$dc08		;Sync raster to TOD Clock Frequency
	beq	.wait_raster
	
	ldx	#0		;Prep X and Y for 16 bit
	ldy	#0		; counter operation
	lda	$dc08		;Read deciseconds
.loop1
  inx			;2   -+
	bne	.loop2		;2/3  | Do 16 bit count up on
	iny			;2    | X(lo) and Y(hi) regs in a 
	jmp	.loop3		;3    | fixed cycle manner
.loop2
  nop			;2    |
	nop			;2   -+
.loop3
  cmp	$dc08		;4 - Did 1 decisecond pass?
	beq	.loop1		;3 - If not, loop-di-doop
				;Each loop = 16 cycles
				;If less than 118230 cycles passed, TOD is 
				;clocked at 60Hz. If 118230 or more cycles
				;passed, TOD is clocked at 50Hz.
				;It might be a good idea to account for a bit
				;of slack and since every loop is 16 cycles,
				;28*256 loops = 114688 cycles, which seems to be
				;acceptable. That means we need to check for
				;a Y value of 28.

	cpy	#28		;Did 114688 cycles or less go by?
	bcc	.hertz_correct		;- Then we already have correct 60Hz $dc0e value
	lda	#$80		;Otherwise, we need to set it to 50Hz
	sta	$dc0e
.hertz_correct
	lda	#$1b		;Enable the display again
	sta	$d011
  cli
	rts		


print_errorcode
  print #error_code
  nb65call #NB65_GET_LAST_ERROR
  nb65call #NB65_PRINT_HEX
  print_cr
  rts

;http callback - will be executed whenever data arrives on the TCP connection
http_callback  
  
  ldaxi #nb65_param_buffer
  nb65call #NB65_GET_INPUT_PACKET_INFO  
  lda nb65_param_buffer+NB65_PAYLOAD_LENGTH+1
  cmp #$ff
  bne .not_eof
  lda #1
  sta connection_closed
  rts
.not_eof  

  lda #"*"
  jsr print_a
  ldax nb65_param_buffer+NB65_PAYLOAD_POINTER
  stax tcp_inbound_data_ptr
  ldax nb65_param_buffer+NB65_PAYLOAD_LENGTH 
  stax tcp_inbound_data_length
  
;copy this chunk to our input buffer
  ldax tcp_buffer_ptr  
  stax nb65_param_buffer+NB65_BLOCK_DEST
  ldax tcp_inbound_data_ptr
  stax nb65_param_buffer+NB65_BLOCK_SRC
  ldax tcp_inbound_data_length
  stax nb65_param_buffer+NB65_BLOCK_SIZE
  ldaxi #nb65_param_buffer
  nb65call #NB65_BLOCK_COPY


;increment the pointer into the input buffer  
  clc
  lda tcp_buffer_ptr
  adc tcp_inbound_data_length
  sta tcp_buffer_ptr
  sta temp_ptr
  lda tcp_buffer_ptr+1
  adc tcp_inbound_data_length+1
  sta tcp_buffer_ptr+1  
  sta temp_ptr
  
;put a null byte at the end (assumes we have set temp_ptr already)
  lda #0
  tay
  sta (temp_ptr),y
    
;look for CR or LF in input
  sta found_eol
  ldaxi #scratch_buffer
  stax get_next_byte+1

.look_for_eol
  jsr get_next_byte
  cmp #$0a
  beq .found_eol    
  cmp #$0d
  bne .not_eol
.found_eol  
  inc found_eol
  rts
.not_eol  
  cmp #0
  bne .look_for_eol 
  rts


;constants
nb65_api_not_found_message dc.b "ERROR - NB65 API NOT FOUND.",13,0
incorrect_version dc.b "ERROR - NB65 API MUST BE AT LEAST VERSION 2.",13,0

nb65_signature dc.b $4E,$42,$36,$35  ; "NB65"  - API signature
initializing dc.b "INITIALIZING ",13,0
error_code dc.b "ERROR CODE: $",0
error_while_waiting dc.b "ERROR WHILE "
waiting dc.b "WAITING FOR CLIENT CONNECTION",13,0
press_a_key_to_continue    dc.b "PRESS ANY KEY TO CONTINUE",0
mode dc.b " MODE",13,0
disconnected dc.b 13,"CONNECTION CLOSED",13,0
failed dc.b "FAILED ", 0
ok dc.b "OK ", 0
timeout dc.b 13,"CONNECTION TIMEOUT ",13, 0

transmission_error dc.b "ERROR WHILE SENDING ",0
http: dc.b "HTTP: ",0
gopher: dc.b "GOPHER: ",0
;self modifying code
get_next_byte
  lda $ffff
  inc get_next_byte+1
  bne .skip
  inc get_next_byte+2
.skip
  rts


;variables
protocol ds.b 1
connection_closed ds.b 1
connection_timeout_seconds ds.b 1 
found_eol ds.b 1
nb65_param_buffer DS.B $20  
tcp_buffer_ptr  ds.b 2
scan_ptr  ds.b 2
tcp_inbound_data_ptr ds.b 2
tcp_inbound_data_length ds.b 2
selector: ds.b $100
scratch_buffer: ds.b $1000
index_html_buffer: ds.b $1000
gopher_map_buffer: ds.b $1000
