
.include "../inc/common.i"
.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif


SERVER_PORT=1541
.define SERVERNAME  "COMMODORESERVER.COM"

.import ip65_init
.import dhcp_init
.import tcp_connect
.import dns_resolve
.import dns_set_hostname
.import dns_ip
.import	print_a
.import tcp_connect_ip
.import tcp_send
.import tcp_send_data_len
.import tcp_send_string
.import tcp_connect
.import tcp_close
.import tcp_callback
.import ip65_process
.import ip65_error
.import tcp_state
.import copymem
.import check_for_abort_key
.import tcp_inbound_data_ptr
.import tcp_inbound_data_length
.import tcp_send_keep_alive  
.import get_key
.importzp copy_src
.importzp copy_dest
.export keep_alive_counter
pptr=copy_src
IERROR=$300
CINV=$314
ILOAD=$330
ISAVE=$332

FNLEN		=	$B7
FNADDR		=	$BB
CHRGOT=$79
TXTPTR=$7A
MEMSIZ	=	$37		;highest address used by BASIC
.import __CODE_LOAD__
.import __CODE_RUN__
.import __CODE_SIZE__

.import __RODATA_LOAD__
.import __RODATA_RUN__
.import __RODATA_SIZE__

.import __DATA_LOAD__
.import __DATA_RUN__
.import __DATA_SIZE__

.import __IP65_DEFAULTS_LOAD__
.import __IP65_DEFAULTS_RUN__
.import __IP65_DEFAULTS_SIZE__

.import __CODESTUB_LOAD__
.import __CODESTUB_RUN__
.import __CODESTUB_SIZE__

.segment "STARTUP"    ;this is what gets put at the start of the file on the C64
.word basicstub		; load address
basicstub:
	.word @nextline
	.word 10    ;line number
	.byte $9e     ;SYS
	.byte <(((relocate / 1000) .mod 10) + $30)
	.byte <(((relocate / 100 ) .mod 10) + $30)
	.byte <(((relocate / 10  ) .mod 10) + $30)
	.byte <(((relocate       ) .mod 10) + $30)
	.byte 0
@nextline:
	.word 0  
relocate:  


  ;relocate everything
	ldax #__CODE_LOAD__
	stax copy_src
	ldax #__CODE_RUN__
	stax copy_dest
	ldax #__CODE_SIZE__
	jsr __copymem
	
  
	ldx ILOAD+1
  cpx #>load_handler
	bne	@not_installed
	ldax #@already_installed_msg    
	jsr	__print
	rts
  
  @installed_msg: .byte "V1541 INSTALLED",0
  @already_installed_msg: .byte "V1541 ALREADY INSTALLED",0
@not_installed:
  
  
	ldax #__DATA_LOAD__
	stax copy_src
	ldax #__DATA_RUN__
	stax copy_dest
	ldax #__DATA_SIZE__
	jsr __copymem
	
	ldax #__CODESTUB_LOAD__
	stax copy_src
	ldax #__CODESTUB_RUN__
	stax copy_dest
	ldax #__CODESTUB_SIZE__
	jsr __copymem
	
	ldax #__RODATA_LOAD__
	stax copy_src
	ldax #__RODATA_RUN__
	stax copy_dest
	ldax #__RODATA_SIZE__
	jsr __copymem
	
	ldax #__IP65_DEFAULTS_LOAD__
	stax copy_src
	ldax #__IP65_DEFAULTS_RUN__
	stax copy_dest
	ldax #__IP65_DEFAULTS_SIZE__
	jsr __copymem
	

  
	
  jsr	swap_basic_out
  
	jsr	ip65_init
  bcc @init_ok
  ldax #@no_nic
  jsr	print
@fail_and_exit:
  ldax #@not_installed_msg
  jsr print
  jmp	@done
@no_nic: .byte "NO RR-NET FOUND - ",0
@not_installed_msg: .byte "V1541 NOT INSTALLED.",0  
@init_ok:
  ldax #@dhcp_init_msg
  jsr print
	jsr	dhcp_init
  bcc @dhcp_worked
@failed:  
  ldax #@fail_msg
  jsr print
  jmp @fail_and_exit
@dhcp_init_msg: .byte "DHCP INITIALISATION"
@elipses: .byte "...",0
@ok_msg: .byte "OK",13,0
@fail_msg: .byte "FAILED",13,0
@dhcp_worked:  
  ldax #@ok_msg  
  jsr print
  
  ldax #@resolve_servername_msg
  jsr print
  ldax  #@elipses
  jsr print
  ldax #@servername
  jsr dns_set_hostname
  jsr dns_resolve  
  bcc @dns_worked
  jmp @failed
@resolve_servername_msg: .byte "RESOLVING "
@servername: .byte SERVERNAME,0
@dns_worked:
  ldax #@ok_msg  
  jsr print
  ldx #3
@copy_server_ip_loop:
  lda dns_ip,x
  sta tcp_connect_ip,x
  dex
  bpl @copy_server_ip_loop

  ldax #@connecting_msg
  jsr print
  ldax #@servername
  jsr print
  ldax  #@elipses
  jsr print
  ldax  #csip_callback
  stax  tcp_callback
  ldax #SERVER_PORT  
  jsr tcp_connect
  bcc @connect_worked
  jmp @failed
@connecting_msg:  .byte "CONNECTING TO ",0

@connect_worked:  
  ldax #@ok_msg  
  jsr print
  ;IP stack OK, now set vectors  
  
  ldax CINV
  stax  old_irq_vector
  
	ldax ILOAD
	stax old_load_vector	
	ldax #load_handler
	stax ILOAD
	ldax #@installed_msg
	jsr	print

ldax #irq_handler
  sei
  stax CINV  
  
;  jsr install_wedge
  
@done:	
	jsr	swap_basic_in
  lda #0
  sta $dc08 ;make sure TOD clock is started
  cli
	rts
	
__copymem:
	sta end
	ldy #0

	cpx #0
	beq @tail

:	lda (copy_src),y
	sta (copy_dest),y
	iny
	bne :-
  inc copy_src+1    ;next page
  inc copy_dest+1  ;next page
	dex
	bne :-

@tail:
	lda end
	beq @done

:	lda (copy_src),y
	sta (copy_dest),y
	iny
	cpy end
	bne :-

@done:
	rts

end: .byte 0	

__print:
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

install_wedge:
  ldax #wedge_start
  stax copy_src  
  sec
  lda MEMSIZ
  sbc #<wedge_length
  sta MEMSIZ
  sta copy_dest
  sta IERROR
  lda MEMSIZ+1
  sbc #>wedge_length
  sta MEMSIZ+1
  sta copy_dest+1
  sta IERROR+1
  ldax #wedge_length  
  jsr __copymem  
  jmp  $a644	;NEW
  
wedge_start:

  
  ;new error handler
  cpx #$0b	; is it a SYNTAX ERROR?
	beq @syntax_error; yes, jump to command test
@exit:
	jmp $e38b	;nope, normal error handler

@syntax_error:	
 
	jsr CHRGOT	;read current character in buffer again
  bcc @exit  
	cmp #$b1		;is current character a > token?    
	bne @exit	;nope, normal error handler
@got_it:  
	ldy #0
  lda #'>'
  sta (TXTPTR),y	;replace token with > symbol again
@scan_command:
	lda (TXTPTR),y	;
	beq @end_of_command
	cmp #':'
	beq @end_of_command
	iny
	bne @scan_command
@end_of_command:
	sty FNLEN	;file name length
	lda TXTPTR	;start of filename
	sta FNADDR	
	lda TXTPTR+1	;start of filename
	sta FNADDR+1
	lda #$2
	sta $BA		;current device number
  ;jmp (ILOAD)
  jsr load_handler
  jmp $A474  ;READY prompt
	

wedge_length=*-wedge_start

.code

load_dev_2:
  ldy #$00
  lda (FNADDR),y
  cmp #'!'
  beq @do_disks
  cmp #'>'
  beq @do_command
  cmp #'#'  
  beq @do_insert

@done:
  clc  
	jmp	swap_basic_in

@do_command:
  ldy FNLEN
@copy_cmd:
  lda (FNADDR),y
  sta cmd_buffer-1,y
  dey
  bne @copy_cmd
  
  
  ldy FNLEN
  lda #$0D
  sta cmd_buffer-1,y
  lda #0
  sta cmd_buffer,y
@send_command_buffer:  
  ldax #cmd_buffer
  jmp @send_string_show_list
  
@do_disks:
	ldax	  #@cmd_dsks
@send_string_show_list:
  jsr tcp_send_string	
  bcs @error
	jsr show_list
	jmp @done

@cmd_dsks:    .byte "DISKS 22",$0d,$0

@do_insert:

  ldx #0
@copy_insert:  
  lda @cmd_insert,x
  beq @end_insert
  sta cmd_buffer,x
  inx
  bne @copy_insert
@end_insert:  
  ldy #1
:  
  lda (FNADDR),y  
  sta cmd_buffer,x
  iny
  inx
  cpy FNLEN
  
  bne :-
  
  lda #$0D
  sta cmd_buffer,x
  lda #0
  sta cmd_buffer+1,x
  jmp @send_command_buffer

@cmd_insert:    .byte "INSERT ",0


@error:
  ldax #transmission_error
  jsr print
  lda ip65_error
  jsr print_hex
  lda tcp_state
  jsr print_hex

  jmp @done


show_list:

@loop:
  lda $91     ; look for STOP key
  cmp #$7F
  beq @done
  lda #2 ;wait for max 2 seconds
  jsr getc
  bcc @got_data
  rts
@got_data:
  cmp #$03		;ETX byte (indicating end of page)?
  beq @get_user_input
  cmp #$04		;EOT byte (indicating end of list)?
  beq @done
	jsr print_a	;got a byte - output it
  jmp @loop ;continue getting characters

;End of page, so ask for user input
 @get_user_input:
  jsr get_key
  
  cmp #'S'
  beq @user_exit

  cmp #$0D
  bne @get_user_input
  ldax #continue_cmd

  jsr tcp_send_string
  jmp @loop

;User wishes to stop - send S to server and quit
@user_exit:
  ldax  #stop_cmd  
  jsr tcp_send_string

@done:

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


csip_callback:
  lda tcp_inbound_data_length+1
  cmp #$ff
  bne @not_eof
  rts
@not_eof:
  
  ldax tcp_inbound_data_ptr
  stax copy_src
  ldax #csip_stream_buffer
  stax copy_dest
  stax next_char_ptr

  ldax tcp_inbound_data_length
  stax buffer_length
  jsr copymem
  rts

getc:
  sta getc_timeout_seconds

  clc
  lda $dc09  ;time of day clock: seconds (in BCD)
  sed
  adc getc_timeout_seconds
  cmp #$60
  bcc @timeout_set
  sec
  sbc #$60
@timeout_set:  
  cld
  sta getc_timeout_end  

@poll_loop: 
  jsr next_char
  bcs @no_char
  rts ;done!
@no_char:  
  jsr check_for_abort_key
  bcc @no_abort
  lda #KPR_ERROR_ABORTED_BY_USER
  sta ip65_error
  inc user_abort
  rts
@no_abort:  
  jsr ip65_process
  lda $dc09  ;time of day clock: seconds
  cmp getc_timeout_end  
  bne @poll_loop
  lda #00
  sec
  rts

next_char:
  lda buffer_length
  bne @not_eof
  lda buffer_length+1
  bne @not_eof
  sec
  rts
@not_eof:  
  next_char_ptr=*+1
  lda $ffff
  pha
  inc next_char_ptr
  bne :+
  inc next_char_ptr+1
:  
  sec
  lda   buffer_length
  sbc #1
  sta   buffer_length
  lda   buffer_length+1
  sbc #0
  sta   buffer_length+1
  pla
  clc  
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
hexdigits:
.byte "0123456789ABCDEF"

tcp_irq_handler:

  inc keep_alive_counter
  lda keep_alive_counter
  bne @skip
  jsr tcp_send_keep_alive  
@skip:  
  jsr ip65_process
@done:  

  rts
  


.segment "CODESTUB"

swap_basic_out:
	lda $01
  sta underneath_basic
	and #$FE
	sta $01
	rts

swap_basic_in:
	lda $01
	ora #$01
	sta $01
  lda #$0  
  sta underneath_basic
	rts

load_handler:
	ldx $BA       ; Current Device Number
	cpx	#$02
	beq	:+
	.byte $4c	;jmp
old_load_vector:	
	.word	$ffff	
	:
	jsr	swap_basic_out
	jmp	load_dev_2

irq_handler:
  lda underneath_basic
  bne @done 
  jsr swap_basic_out
  jsr tcp_irq_handler
  jsr	swap_basic_in
@done:  
	.byte $4c	;jmp
old_irq_vector:	
	.word	$ffff	

underneath_basic: .res 1

.segment "TCP_VARS"
csip_stream_buffer: .res 1400
cmd_buffer: .res 100
user_abort: .res 1
getc_timeout_end: .res 1
getc_timeout_seconds: .res 1
buffer_length: .res 2  
keep_alive_counter: .res 1

.data
continue_cmd: .byte $0D,0
stop_cmd: .byte "S",0

transmission_error: .byte "TRANSMISSION ERROR",13,0

;-- LICENSE FOR v1541.s --
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
; The Original Code is ip65.
; 
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2010
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
