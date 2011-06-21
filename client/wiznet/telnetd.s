; #############
;
; jonno@jamtronix.com - June 2011
; Telnet server cartridge
;

TELNET_PORT=6400
  .include "../inc/common.i"
  .include "commonprint.i"

  .import ip65_init
  .import dhcp_init
  .import w5100_set_ip_config
  .import cls
  .import beep
  .import exit_to_basic
  .import timer_vbl_handler
  .import get_key_ip65   
  .import cfg_mac
  .import cfg_size
  .import cfg_ip
  .import cfg_netmask
  .import cfg_gateway
  .import cfg_dns
  .import cfg_tftp_server
  .import cfg_get_configuration_ptr
  .import ip65_process
  .import copymem
  .import tcp_listen
  .import tcp_callback
  .import tcp_send
  .import tcp_send_data_len
  .import tcp_inbound_data_length
  .import tcp_inbound_data_ptr
  .import tcp_connected
  .importzp copy_src
  .importzp copy_dest
  buffer_ptr=copy_dest
  .import  __DATA_LOAD__
  .import  __DATA_RUN__
  .import  __DATA_SIZE__
  .import  __SELF_MODIFIED_CODE_LOAD__
  .import  __SELF_MODIFIED_CODE_RUN__
  .import  __SELF_MODIFIED_CODE_SIZE__
  

   CINV=$314 ;vector to IRQ interrupt routine
   ISTOP=$328;vector to kernal routine to check if STOP key pressed
   KEYD=$277 ;input keyboard buffer
   NDX=$C6	 ;number of keypresses in buffer
   XMAX=$289 ;max keypresses in buffer
   STKEY=$91 ;last key pressed
   
  INIT_MAGIC_VALUE=$C7	 
.segment "CARTRIDGE_HEADER"
.word cold_init  ;cold start vector
.word warm_init  ;warm start vector
.byte $C3,$C2,$CD,$38,$30 ; "CBM80"
.byte $0,$0,$0             ;reserved for future use
.byte $0,$0,$0             ;reserved for future use
.byte $0,$0,$0             ;reserved for future use
.byte $0,$0,$0             ;reserved for future use
.byte $0,$0,$0             ;reserved for future use

.code

  
  
cold_init:
  
  ;first let the kernal do a normal startup
  sei
  jsr $fda3   ;initialize CIA I/O
  jsr $fd50   ;RAM test, set pointers
  jsr $fd15   ;set vectors for KERNAL
  jsr $ff5B   ;init. VIC
  cli         ;KERNAL init. finished
    
warm_init:
 lda #INIT_MAGIC_VALUE
 cmp init_flag
 bne @real_init
 jmp $fe5e ; contine on to real RESTORE routine
@real_init:
 sta init_flag
 
 
 ;we need to set up BASIC as well  
  jsr $e453   ;set BASIC vectors
  jsr $e3bf   ;initialize zero page

;relocate our r/w data
  ldax #__DATA_LOAD__
  stax copy_src
  ldax #__DATA_RUN__
  stax copy_dest
  ldax #__DATA_SIZE__
  jsr copymem
  ldax #__SELF_MODIFIED_CODE_LOAD__
  stax copy_src
  ldax #__SELF_MODIFIED_CODE_RUN__
  stax copy_dest
  ldax #__SELF_MODIFIED_CODE_SIZE__
  jsr copymem


;set normal BASIC colour
  LDA #$0e  ;light blue  
  STA $D020 ;border
  LDA #$06	;dark blue
  STA $D021 ;background
  lda #$9a
  jsr	print_a

  ;copy KERNAL to RAM so we can patch it


  ldax #startup_msg
  jsr print
  jsr ip65_init
  
  bcs init_failed
  jsr dhcp_init
  bcc init_ok
init_failed:  

  jsr print_errorcode
  jsr print_ip_config
  jsr print_cr
  
flash_forever:  
  inc $d020
  jmp flash_forever
init_ok:
  
;install our new IRQ handler
  sei
  ldax	CINV
  stax	old_tick_handler
  ldax #tick_handler
  stax	CINV

;install our new STOP handler
  
  ldax	ISTOP
  stax	old_stop_handler
  ldax #stop_handler
  stax	ISTOP

  cli
  
start_listening:

  ldax #telnet_callback
  stax tcp_callback
  ldax #listening
  jsr	print
  ldax	#cfg_ip
  jsr  print_dotted_quad
  ldax #port
  jsr	print
 
   ;we need to copy BASIC as well since swapping KERNAL forces swap of BASIC
  ldax #$8000
  stax copy_src
  stax copy_dest
  ldax #$4000
  jsr copymem

  ldax #$E000
  stax copy_src
  stax copy_dest
  ldax #$2000
  jsr copymem

  ;now intercept calls to $E716
  ;we do this instead of using the $326 vector because the BASIC
  ;'READY' loop calls $E716 directly rather than calling $FFD2 

  lda #$4C				;JMP
  sta $e716
  ldax #new_charout
  stax $e717
  

  ;swap out BASIC & KERNAL
  lda #$35
  sta $01 


  ldax #TELNET_PORT
  jsr	tcp_listen
  ldax #term_setup_string_length
  sta tcp_send_data_len
  ldax #term_setup_string
  jsr	tcp_send
	

  jmp $E397

wait_for_keypress:
  ldax  #press_a_key_to_continue
  jsr print
@loop:  
  jsr $ffe4
  beq @loop
  rts

get_key:
@loop:  
  jsr $ffe4
  beq @loop
  rts


tick_handler:	;called at least 60hz via $314
	lda sending_flag
	bne @done
	inc	jiffy_count
	lda jiffy_count
	cmp #$06		;about 100ms
	bne @done
	lda #0
	sta jiffy_count
	lda tcp_connected
	beq @done
	jsr ip65_process
@done:	
	jmp	(old_tick_handler)


telnet_callback:
  lda tcp_inbound_data_length+1
  cmp #$ff
  bne @not_eof
  ldax #connection_closed
  jsr print
  
  jmp start_listening
  
@not_eof:
  ldax tcp_inbound_data_ptr
  stax buffer_ptr  
  ldy	#0
  
@next_byte:
  ldx 	NDX
  cpx	XMAX
  beq	@done

  lda	(buffer_ptr),y
  cmp	#$03	;is ^C?
  bne	@not_ctrl_c
  inc	break_flag
  jmp	@key_done
@not_ctrl_c: 
  inc	NDX
  sta	KEYD,x
@key_done:  
  iny
  cpy	tcp_inbound_data_length
  bne @next_byte
 @done:
 rts

new_charout:
	pha			;original $e716 code we patched over
	sta	$d7		;original $e716 code we patched over
	stx	temp_x
	sty	temp_y
	sta output_buffer
	pha
	ldax #1
	sta tcp_send_data_len
	sta	sending_flag
	ldax #output_buffer
	jsr	tcp_send
	dec sending_flag
	pla
	ldx	temp_x
	ldy	temp_y
	jmp	$e719	;after the code we patched

stop_handler:	

	lda break_flag
	beq @no_stop
	
	lda #$7F
	sta $91
	lda #0
	sta break_flag
@no_stop:
	jmp (old_stop_handler)

.bss
init_flag: .res 1
old_tick_handler: .res 2
old_stop_handler: .res 2
temp_x	: .res 1
temp_y	: .res 1
output_buffer: .res 64

.data
jiffy_count: .byte 0
break_flag: .byte 0
sending_flag: .byte 0
.rodata

startup_msg: 
.byte 147	;cls
;.byte 14	;lower case
.byte 142	;upper case
.byte 13,"TELNETD "
.include "../inc/version.i"
.include "timestamp.i"
.byte 13
.byte 0
listening:
.byte 13,"LISTENING ON "
.byte 0
port:
.byte ":"
.if (TELNET_PORT > 999 )
.byte <(((TELNET_PORT / 1000) .mod 10) + $30)
.endif
.if TELNET_PORT>99
.byte <(((TELNET_PORT / 100 ) .mod 10) + $30)
.endif 
.byte <(((TELNET_PORT / 10  ) .mod 10) + $30)
.byte <(((TELNET_PORT       ) .mod 10) + $30)
.byte 13
.byte "HIT RUN/STOP TO ABORT"
.byte 0

connection_closed:
.byte 13,"CONNECTION CLOSED",13,0

term_setup_string:

	.byte 142	;upper case
	.byte 147	;cls
term_setup_string_length=*-term_setup_string
	
;we need a 'dummy' segment here - some drivers use this segment (e.g. wiznet), some don't (e.g. rr-net)
;if we don't declare this, we get an 'undefined segment' error when linking to a driver that doesn't use it.
.segment "SELF_MODIFIED_CODE"  

;-- LICENSE FOR wizboot.s --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
; 
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
; 
; The Original Code is wizboot.
; 
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2011
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
