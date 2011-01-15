
.ifndef SCREEN_WIDTH
  SCREEN_WIDTH = 22
.endif

.include "../inc/common.i"
.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

VARTAB	=	$2D		;BASIC variable table storage
ARYTAB	=	$2F		;BASIC array table storage
FREETOP	=	$33		;bottom of string text storage area
MEMSIZ	=	$37		;highest address used by BASIC
VARNAM = $45 ;current BASIC variable name
VARPNT = $47 ; pointer to current BASIC variable value

SETNAM	=	$FFBD
SETLFS	=	$FFBA 
OPEN	=	$FFC0
CHKIN	=	$FFC6
READST	=	$FFB7     ; read status byte
CHRIN	=	$FFCF     ; get a byte from file
CLOSE	=	$FFC3
MEMTOP  = $FE25                          
TXTPTR  = $7A            ;BASIC text pointer
IERROR  = $0300          
ICRUNCH = $0304          ;Crunch ASCII into token
IQPLOP  = $0306          ;List
IGONE   = $0308          ;Execute next BASIC token
IEVAL = $30A              ; evaluate expression                          
CHRGET  = $73            
CHRGOT  = $79            
CHROUT  = $FFD2          
GETBYT  = $D79E          ;BASIC routine
GETPAR  = $D7EB          ;Get a 16,8 pair of numbers
CHKCOM  = $CEFD          
NEW     = $C642          
CLR     = $C65E
NEWSTT	= $C7AE
GETVAR = $D0E7          ;find or create a variable
FRMEVL = $CD9E    ;evaluate expression
FRESTR = $D6A3  ;free temporary string
FRMNUM = $CD8A ;get a number
GETADR = $D7F7 ;convert number to 16 bit integer
INLIN = $C560 ; read a line from keyboard

VALTYP=$0D  ;00=number, $FF=string

LINNUM   = $14            ;Number returned by GETPAR

crunched_line      = $0200          ;Input buffer

.import copymem
.importzp copy_src
.importzp copy_dest
.import dhcp_init
.import ip65_init
.import cfg_get_configuration_ptr
.import tcp_listen
.import tcp_callback
.import tcp_connect_ip
.import tcp_send
.import tcp_connect
.import tcp_close
.import tcp_send_data_len
.import tcp_inbound_data_ptr
.import tcp_inbound_data_length
.import dns_set_hostname
.import dns_resolve
.import dns_ip
.import ip65_process
.import ip65_error
.import cfg_ip
.import cfg_dns
.import cfg_gateway
.import cfg_netmask
.import cfg_tftp_server
.import icmp_ping
.import icmp_echo_ip
.import print_a
.import print_cr
.import dhcp_server
.import cfg_mac
.import cfg_mac_default
.import eth_driver_name
.importzp tftp_filename
.import tftp_ip
.import tftp_download
.import tftp_set_callback_vector
.import tftp_data_block_length
.import tftp_upload
.import get_key_if_available
.import tcp_send_keep_alive
.import timer_read
.import native_to_ascii
.import ascii_to_native
.zeropage
temp:	.res 2
temp2:	.res 2
pptr=temp
.segment "STARTUP"    ;this is what gets put at the start of the file on the Vic 20
.word basicstub		; load address
basicstub:
	.word @nextline
	.word 10    ;line number
	.byte $9e     ;SYS
	.byte <(((relocate / 1000) .mod 10) + $30)
	.byte <(((relocate / 100 ) .mod 10) + $30)
	.byte <(((relocate / 10  ) .mod 10) + $30)
	.byte <(((relocate       ) .mod 10) + $30)
;	.byte ":"
;	.byte "D"
;	.byte $b2	;=
;	.byte $c2	;PEEK
;	.byte "(186):"
;	.byte $93	;LOAD
;	.byte $22,"AUTOEXEC.BAS",$22,",D"
	.byte 0
@nextline:
	.word 0  
relocate:  
  lda MEMSIZ+1
  cmp	#$80	;standard end of memory
  beq	ok_to_install
  ldy #0
@loop:  
  lda not_installing,y
  beq	@done  
  jsr	$ffd2
  iny
  bne	@loop
@done:
  rts
not_installing:
  .byte "INSUFFICIENT FREE MEMORY",13,0
ok_to_install:  

  ldax  #end_of_loader
  stax  copy_src
  ldax  #main_start
  stax  copy_dest
  stax  MEMSIZ
  FS=   $3FC9	;how much data to relocate?
  ldax  #FS
	
;copy memory
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
  ldax #welcome_banner

  	jsr print

	
	ldx	#7           ;Copy CURRENT vectors
@copy_old_vectors_loop:
	lda ICRUNCH,x
	sta	oldcrunch,x
	dex
	bpl	@copy_old_vectors_loop

	ldx	#7           ;Copy CURRENT vectors
install_new_vectors_loop:
	lda vectors,x
	sta	ICRUNCH,x
	dex
	bpl	install_new_vectors_loop
    
  ;BASIC keywords installed, now bring up the ip65 stack
    
  jsr ip65_init
  bcc @init_ok
  bcs	@init_ok	;FIXME
  ldax #@no_nic
  jsr	print
@reboot:  
  	
  ldax  #$8000
  stax  MEMSIZ

  jsr	$e45b	;reset vectors
    
  jsr	$c642	;NEW
  jsr	$c65e	;CLR
  jsr	$e3a4	;init RAM
  jmp 	$e467 	;BASIC warm start
  
@no_nic:
  .byte "NO RR-NET FOUND!",13,0  
  
@init_ok:

  lda #0
  sta ip65_error  
  sta connection_state
  jsr		set_error

@exit:

 ; jsr $C644 ;do a "NEW"
 ; jmp $C474 ;"READY" prompt
   jmp 	$e467 	;BASIC warm start
  rts
	
welcome_banner:
.byte "** KIPPER BASIC 1.1 **"
.byte 0
end:  .res  1
end_of_loader:

.segment "MAINSTART"
main_start:

safe_getvar:      ;if GETVAR doesn't find the desired variable name in the VARTABLE, a routine at $D11D will create it
                  ;however that routine checks if the low byte of the return address of the caller is $2A. if it is,
                  ;it assumes the caller is the routine at $CF28 which just wants to get the variable value, and
                  ;returns a pointer to a dummy 'zero' pointer.
                  ;so if user code that is calling GETVAR happens to be compiled to an address $xx28, it will 
                  ;trigger this check, and not create a new variable, which (from painful experience) will create
                  ;a really nasty condition to debug!
                  ;so vector to GETVAR via here, so the return address seen by $D11D is here, and never $xx28
  jsr GETVAR
  rts
.code  

		
; CRUNCH -- If this is one of our keywords, then tokenize it
;
crunch:                    
	jsr jmp_crunch   ;First crunch line normally
    ldy #05          ;Offset for KERNAL
                          ;Y will contain line length+5
@loop:	
	sty temp
	jsr	isword		  ;Are we at a keyword?
	bcs	@gotcha
@next:
	jsr	nextchar
	bne	@loop	      ;Null byte marks end
	sta	crunched_line-3,Y       ;00 line number
	lda #$FF          ;'tis what A should be
	rts               ;Buh-bye
        
; Insert token and crunch line
@gotcha:
	ldx	temp         ;If so, A contains opcode
	sta crunched_line-5,X      
@move:
	inx
	lda crunched_line-5,Y      
	sta crunched_line-5,X      ;Move text backwards
	beq @next
	iny
	bpl @move
                          

; ISWORD -- Checks to see if word is
; in table.  If a word is found, then
; C is set, Y is one past the last char
; and A contains opcode.  Otherwise,
; carry is clear.
;
; On entry, TEMP must contain current
; character position.
;
isword:                    
	ldx #00          
@loop:
	ldy temp
@loop2:
	lda keywords,x
	beq	@notmine
	cmp	#$E0
	bcs	@done		;Tokens are >=$E0
	cmp crunched_line-5,Y      
	bne	@next
	iny   ;Success!  Go to next char
	inx
	bne	@loop2
@next:
	inx
	lda keywords,x	;Find next keyword
	cmp	#$E0
	bcc	@next
	inx
	bne	@loop       ;And check again
@notmine:
	clc
@done:	
	rts


; NEXTCHAR finds the next char
; in the buffer, skipping
; spaces and quotes.  On
; entry, TEMP contains the
; position of the last spot
; read.  On exit, Y contains
; the index to the next char,
; A contains that char, and Z is set if at end of line.

nextchar:
	ldy	temp
@loop:
	iny
	lda	crunched_line-5,Y
	beq	@done
	cmp #$8F         ;REM
	bne	@cont
	lda	#00
@skip:
	sta	temp2        ;Find matching character
@loop2:
	iny
	lda	crunched_line-5,Y
	beq	@done
	cmp	temp2
	bne	@loop2		;Skip to end of line
	beq	@loop
@cont:
	cmp #$20 		;space
	beq	@loop
	cmp #$22		;quote
	beq	@skip
@done:
	rts


;
; LIST -- patches the LIST routine
; to list our new tokens correctly.
;

list:
	cmp #$E0
	bcc	@notmine	;Not my token
	cmp	#HITOKEN
	bcs	@notmine
	bit $0F          ;Check for quote mode
	bmi	@notmine
	sec
	sbc	#$DF         ;Find the corresponding text
	tax
	sty	$49
	ldy	#00
@loop:
	dex
	beq	@done
@loop2:
	iny
	lda	keywords,y
	cmp	#$E0
	bcc	@loop2
	iny
	bne	@loop
@done:
  lda keywords,y
  cmp #$91    ;is it "ON"?
  bne @not_on
  lda #'O'
  jsr CHROUT
  lda #'N'
  bne @skip
  
@not_on:  
  cmp #$9B    ;is it "LIST"?

  bne @not_list
  lda #'L'
  jsr CHROUT
  lda #'I'
  jsr CHROUT
  lda #'S'
  jsr CHROUT  
  lda #'T'
  bne @skip
@not_list:
	lda	keywords,y
	bmi	@out  ;is it >=$80?
@skip:
	jsr	CHROUT
	iny
	bne	@done
@out:
	cmp	#$E0		         ;It might be BASIC token
	bcs	@cont
	ldy	$49          
@notmine:
	and #$FF
	jmp	(oldlist)
@cont:
	ldy $49          
	jmp $C700        ;Normal exit



;
; EXECUTE -- if this is one of our new 
; tokens, then execute it.
execute:                          
	jsr	CHRGET
execute_a:
  php
  cmp #':'  ;is it a colon?
  beq	execute;if so, skip over and go to next token
  cmp #$8B  ;is it 'IF'?
  bne @not_if
  lda #$E0  ;our dummy IF token
@not_if:  
	cmp	#$E0
	bcc	@notmine
	cmp #HITOKEN
	bcs	@notmine
	plp
	jsr	@disp
	jmp	NEWSTT
@disp:
	eor	#$E0
	asl		;multiply by 2
	tax
	lda	token_routines+1,x
	pha
	lda	token_routines,x
	pha
	jmp	CHRGET	;exit to routine (via RTS)
@notmine:
	plp
	cmp	#0 ;reset flags
	jmp $C7E7

;the standard BASIC IF routine calls the BASIC EXECUTE routine directly,
;without going through the vector. That means an extended keyword following THEN 
;will lead to a syntax error. So we have to reimpliment IF here
;this is taken from TransBASIC - The Transactor, vol 5, Issue 04 (March 1985) page 34  
if_keyword:  
  jsr FRMEVL      ;evaluate expression
  jsr CHRGOT  
  cmp #$89        ;is next token GOTO?
  beq @ok
  lda #$A7        ;is next token THEN
  jsr $CEFF       ;will generate SYNTAX ERROR if not  
@ok:
  jsr CHRGOT
  ldx $61         ;result of expression : 0 means false
  bne @expression_was_true
  jmp $C93B       ;go to REM implementation - skips rest of line
@expression_was_true:
  bcs @not_numeric;CHRGOT clears carry flag if current char is a number
  jmp $C8A0       ;do a GOTO
@not_numeric:  
  pla
  pla           ;pop the return address off the stack
  jsr CHRGOT
  jmp   execute_a ;execute current token  



find_var:
  sta VARNAM
  stx VARNAM+1
  jsr safe_getvar  
  ldy #0
  rts

set_connection_state:  
  lda #'C'+$80 
  ldx #'O'+$80 
  jsr find_var  
  tya
  sta (VARPNT),y  
  iny
  lda connection_state 
  sta (VARPNT),y
    
set_error:
  lda #'E'+$80 
  ldx #'R'+$80 
  sta VARNAM+1
  jsr find_var
  lda #0
  sta (VARPNT),y
  iny
  lda ip65_error
  sta (VARPNT),y

  rts
  

;emit the 4 bytes pointed at by AX as dotted decimals
emit_dotted_quad:
  sta pptr
	stx pptr + 1
  ldy #0
  lda (pptr),y
  jsr emit_decimal 
  lda #'.'
  jsr emit_a

  ldy #1
  lda (pptr),y
  jsr emit_decimal 
  lda #'.'
  jsr emit_a

  ldy #2
  lda (pptr),y
  jsr emit_decimal 
  lda #'.'
  jsr emit_a

  ldy #3
  lda (pptr),y
  jsr emit_decimal
  
  rts

emit_decimal:  ;emit byte in A as a decimal number
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
  bmi @emit_hundreds ; if N is set, the number is >=128 so emit all 3 digits
  cmp #10
  bmi @emit_units
  cmp #100
  bmi @emit_tens
@emit_hundreds:
  lda temp_bcd+1   ;get the most significant digit
  and #$0f
  clc
  adc #'0'
  jsr emit_a

@emit_tens:
  lda temp_bcd
  lsr
  lsr
  lsr
  lsr
  clc
  adc #'0'
  jsr emit_a
@emit_units:
  lda temp_bcd
  and #$0f
  clc
  adc #'0'
  jsr emit_a
  
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


extract_string:

  jsr FRMEVL
  
  jsr FRESTR  ;if not string, will create type mismatch error
  
  sta param_length
  tay
  lda #0
  sta transfer_buffer,y  
  dey
@loop:
  lda ($22),y
  sta transfer_buffer,y  
  dey  
  bpl @loop
  jmp FRESTR  ;free up the temp string created by FRMEVL

;get a string value from BASIC command, turn into a 32 bit IP address,save it in the 4 bytes pointed at by AX
get_ip_parameter:
  stax  temp2
  jsr extract_string
  ldax #transfer_buffer
  jsr dns_set_hostname   
  
  bcs @error
  jsr dns_resolve
  bcc @ok
@error:  
  ldax  #address_resolution
  jmp print_error

@ok:
  ldax #dns_ip
  ldx #4
@copy_dns_ip:
  lda dns_ip,y 
  sta (temp2),y  
  iny
  dex  
  bne @copy_dns_ip  
  rts


reset_string:
  ldy #<string_buffer
  sty current_output_ptr  
  ldy #>string_buffer
  sty current_output_ptr+1
  rts
  
print_dotted_quad:
  jsr reset_string
  jsr emit_dotted_quad
make_null_terminated_and_print:  
  lda #0
  jsr emit_a
  ldax #string_buffer
  jmp print

print_mac:
  jsr reset_string
  jsr emit_mac
  jmp make_null_terminated_and_print

;print 6 bytes printed at by AX as a MAC address  
emit_mac:
  stax pptr  
  ldy #0
@one_mac_digit:
  tya   ;just to set the Z flag
  pha
  beq @dont_print_colon
  lda #':'
  jsr emit_a
@dont_print_colon:
  pla 
  tay
  lda (pptr),y
  jsr emit_hex
  iny
  cpy #06
  bne @one_mac_digit
  rts

emit_hex:
  pha  
  pha  
  lsr
  lsr
  lsr
  lsr
  tax
  lda hexdigits,x
  jsr emit_a
  pla
  and #$0F
  tax
  lda hexdigits,x
  jsr emit_a
  pla
  rts

print_hex:
  jsr reset_string
  jsr emit_hex
  jmp make_null_terminated_and_print

print_error:
  jsr print
  ldax #error
  jsr print
  lda ip65_error
  jsr print_hex
  jsr print_cr
  jsr set_error
  sec
  rts
  
get_optional_byte:  
  jsr CHRGOT
  beq @no_param ;leave X as it was
  jsr CHKCOM  ;make sure next char is a comma (and skip it)
  jsr CHRGOT
  beq @eol 
  jsr GETBYT  
@no_param:
  rts
@eol:
  jmp $CF08 ;SYNTAX ERROR
  
ipcfg_keyword:

  ldax #interface_type
  jsr print

  ldax #eth_driver_name
  jsr print
  jsr print_cr
  
  ldax #mac_address_msg
  jsr print
  ldax #cfg_mac
  jsr print_mac
  jsr print_cr

  ldax #ip_address_msg
  jsr print
  ldax  #cfg_ip
  jsr print_dotted_quad
  jsr print_cr

  ldax #netmask_msg
  jsr print
  ldax #cfg_netmask
  jsr print_dotted_quad
  jsr print_cr

  ldax #gateway_msg
  jsr print
  ldax  #cfg_gateway
  jsr print_dotted_quad
  jsr print_cr

  ldax #dns_server_msg
  jsr print
  ldax  #cfg_dns
  jsr print_dotted_quad
  jsr print_cr


  ldax #dhcp_server_msg
  jsr print
  ldax  #dhcp_server
  jsr print_dotted_quad
  jsr print_cr

 ldax #tftp_server_msg
  jsr print
  ldax  #cfg_tftp_server
  jsr print_dotted_quad
  jsr print_cr

clear_error:
  lda #0
  sta ip65_error
  jmp set_error
  
dhcp_keyword:
  jsr dhcp_init
  bcc @init_ok
  jsr ip65_init   ;if DHCP failed, then reinit the IP stack (which will reset IP address etc that DHCP messed with to default values)
  
@init_failed:  
  jsr		set_error
  ldax  #dhcp
  jmp print_error
@init_ok:
  jmp		clear_error  
 rts

mac_keyword:
  jsr extract_string  
  ldy #2
:  
  lda transfer_buffer,y
  sta cfg_mac_default+3,y
  dey
  bpl:-
  jsr ip65_init
  rts

ping_keyword:
  ldax  #icmp_echo_ip
  jsr get_ip_parameter
  bcc @no_error
  rts
@no_error:  

  ;is there an optional parameter?
  ldx #3
  jsr get_optional_byte
  stx ping_counter
  
  ldax #pinging
  jsr print
  ldax #dns_ip
  jsr print_dotted_quad
  jsr print_cr
  
@ping_loop:  

  jsr   icmp_ping  
  bcs @error
  lda #'.'
@print_and_loop:  
  jsr print_a  
  lda $cb ;current key pressed
  cmp #$18  ;RUN/STOP?
  beq @done
  lda ping_counter
  beq @ping_loop
  dec ping_counter
  cmp #1    
  bne @ping_loop
@done:  
  jsr print_cr
  jmp set_error
@error:
  lda #'!'
  jmp @print_and_loop


myip_keyword:
  ldax #cfg_ip
  jmp get_ip_parameter

dns_keyword:
  ldax #cfg_dns
  jmp get_ip_parameter  

gateway_keyword:
  ldax #cfg_gateway
  jmp get_ip_parameter
  
netmask_keyword:
  ldax #cfg_netmask
  jmp get_ip_parameter  

tftp_keyword:
  ldax #cfg_tftp_server
  jmp get_ip_parameter  


tf_param_setup:  
  jsr print
  jsr extract_string
  ldax  #transfer_buffer
  stax  tftp_filename
  jsr print 
  lda #' '
  jsr print_a
  lda #'('
  jsr print_a
  ldax  #cfg_tftp_server
  jsr print_dotted_quad
  lda #')'
  jsr print_a

  jsr print_cr

  ldx #$03
:
  lda cfg_tftp_server,x
  sta tftp_ip,x
  dex
  bpl :-
  rts

tfget_keyword:
  ldax  #get_msg
  jsr tf_param_setup
  ldax #tftp_download_callback
  jsr tftp_set_callback_vector
  lda #0
  sta file_opened
;make file output name
  lda #'@'
  sta string_buffer
  lda #':'
  sta string_buffer+1
  ldy #$FF
@loop:
  iny  
  lda transfer_buffer,y
  sta string_buffer+2,y
  bne @loop
  iny
  iny
  lda #','
  sta string_buffer,y
  iny
  lda #'P'
  sta string_buffer,y
  iny
  lda #','
  sta string_buffer,y
  iny
  lda #'W'
  sta string_buffer,y  
  iny
  sta string_length
  
  jsr tftp_download
after_tftp_xfer:  
  bcc @no_error
  ldax  #tftp
@error_set:  
  jsr  print_error
@no_error:  
  jsr   close_file
  jmp		set_error
  
close_file:
  lda #$02      ; filenumber 2
  jsr $FFC3     ; call CLOSE  
  rts

open_file:
  ;A,X,Y set up ready for a call to SETNAM for file #2
  jsr $FFBD     ; call SETNAM
  lda #$02      ; file number 2
  ldx $BA       ; last used drive
  
  ldy #$02      ; secondary address 2
  jsr $FFBA     ; call SETLFS

  jmp $FFC0     ; call OPEN

  
tftp_download_callback:

  ;buffer pointed at by AX now contains "tftp_data_block_length" bytes
  stax temp
  
  lda #'.'
  jsr print_a
  lda file_opened
  bne @already_opened
  lda string_length  
  ldx #<string_buffer
  ldy #>string_buffer
  jsr open_file
    
@already_opened:  

  ldx #$02      ; filenumber 2 = output file
  jsr $FFC9     ; call CHKOUT 
  
@copy_one_byte:  
  lda tftp_data_block_length
  bne @not_done  
  lda tftp_data_block_length+1
  beq @done
  
@not_done:
  ldy #2    ;we want to skip the first 2 bytes in the buffer
  lda (temp),y
  jsr $ffd2     ;write byte
  inc temp
  bne :+
  inc temp+1
: 
  lda tftp_data_block_length
  dec  tftp_data_block_length
  cmp #0
  bne @copy_one_byte
  dec  tftp_data_block_length+1
  jmp @copy_one_byte
@done:

  ldx #$00      ; filenumber 0 = console
  jmp $FFC9     ; call CHKOUT 


tfput_keyword:
  ldax  #put_msg
  jsr tf_param_setup
  
  lda param_length  
  ldx #<transfer_buffer
  ldy #>transfer_buffer
  jsr open_file  
  bcs @error
  lda $90 ;get ST
  beq @ok  
@error:
  
  ldx #4  ;"FILE NOT FOUND" error
  jmp $C437   ;error
@ok:
  ldax #tftp_upload_callback
  jsr tftp_set_callback_vector
  jsr tftp_upload
  jmp after_tftp_xfer
  
  
tftp_upload_callback:  
  stax  copy_dest  
  lda #'.'
  jsr print_a
  lda #0
  sta bytes_read
  sta bytes_read+1

  ldx #$02      ; filenumber 2 = output file
  jsr $FFC6     ; call CHKIN (file 2 now used as input)
@loop:  
  jsr $FFCF     ; call CHRIN (get a byte from file)
  ldy #0
  sta (copy_dest),y
  inc copy_dest
  bne :+
  inc copy_dest+1
:  
  inc bytes_read
  bne :+
  inc bytes_read+1
: 
  lda bytes_read+1
  cmp #2
  beq @done
  jsr $FFB7     ; call READST (read status byte)  
  beq @loop      ; nonzero mean either EOF or read error
  
@done:
  ldx #$00      ; filenumber 0 = console
  jsr $FFC6     ; call CHKIN (console now used as input)
  ldax bytes_read
  rts

skip_comma_get_integer:
  jsr CHRGOT
  jsr CHKCOM  ;make sure next char is a comma (and skip it)
get_integer:  
  jsr CHRGOT
  beq @eol 
  jsr FRMNUM
  jsr GETADR
  ldax  LINNUM
@no_param:
  rts
@eol:
  jmp $CF08 ;SYNTAX ERROR


make_tcp_connection:
  lda #0
  sta connection_state
  jsr set_connection_state
  ldax  #tcp_connect_ip
  jsr get_ip_parameter
  bcc @no_error
  rts
@no_error:  
  jsr skip_comma_get_integer
  jsr tcp_connect
  bcc :+
@connect_error:
  ldax #connect
  jmp print_error
:  
  ldax #connected_msg
  jsr print
  lda #1
  sta connection_state
  lda #0
  sta ip65_error
  jsr set_connection_state
  clc
  rts
  
netcat_keyword:
  lda $CC
  sta cursor_state
  lda #$0
  sta $CC ;enable blinking cursor
  ldax #netcat_callback
  stax tcp_callback  
  jsr make_tcp_connection
  bcs @exit
  
  ;is there an optional parameter?
  ldx #0
  jsr get_optional_byte
  stx netcat_mode
@main_polling_loop:
  
  jsr timer_read
  txa
  adc #$20  ;32 x 1/4 = ~ 8seconds
  sta netcat_timeout
@wait_for_keypress:  
  jsr timer_read
  cpx netcat_timeout
  bne @no_timeout
  jsr tcp_send_keep_alive
  jmp @main_polling_loop
@no_timeout:  
  jsr ip65_process
  lda connection_state
  bne @not_disconnected
@disconnected:  
  ldax #disconnected
  jsr print
@exit:
  lda cursor_state
  sta $CC  
  rts
@not_disconnected:
  
  lda netcat_mode  
  beq @not_line_mode
  
  lda #$00
  sta string_length

;process inbound ip packets while waiting for a keypress
@read_line:
  lda $cb ;current key pressed
  cmp #$18  ;RUN/STOP?
  beq @runstop
  jsr ip65_process
  lda connection_state
  beq @disconnected

  jsr $f142 ;not officially documented - where F13E (GETIN) falls through to if device # is 0 (KEYBD)
 
  beq @read_line
  
  cmp #$14               ;Delete
  beq @delete

  cmp #$0d               ;Return
  beq @input_done

  ;End reached?
  ldy string_length
  cpy #$FF
  beq @read_line

  jsr $ffd2             ;Print it
  jsr native_to_ascii
  sta transfer_buffer,y        ;Add it to string  

  inc string_length

  ;Not yet.
  jmp @read_line


@delete:
  ;First, check if we're at the beginning.  
  lda string_length
  bne @delete_ok
  jmp @read_line

  ;At least one character entered.
@delete_ok:
  ;Move pointer back.
  dec string_length

  ;Print the delete char
  lda #$14
  jsr $ffd2

  ;Wait for next char
  jmp @read_line

@input_done:
  jsr reset_cursor
  lda #$0d
  jsr $ffd2 ;print a newline
  ldy string_length
  lda #$0d  
  sta transfer_buffer,y
  iny
  lda #$0a
  sta transfer_buffer,y
  iny
  sty tcp_send_data_len
  jmp @send_buffer
@not_line_mode:

  ;is there anything in the input buffer?
  lda $c6 ;NDX - chars in keyboard buffer
  bne :+ 
  jmp @wait_for_keypress
:  
  lda #0
  sta tcp_send_data_len
  sta tcp_send_data_len+1
@get_next_char:
  lda $cb ;current key pressed
  cmp #$18  ;RUN/STOP?
  bne @not_runstop
@runstop:
  lda  #0
  sta $cb ;overwrite "current key pressed" else it's seen by the tcp stack and the close aborts
  lda cursor_state
  sta $CC  
  
  jmp tcp_close
@not_runstop:
  jsr $ffe4 ;getkey - 0 means no input
  tax  
  beq @no_more_input
  txa
  
  ldy tcp_send_data_len
  sta transfer_buffer,y
  inc tcp_send_data_len
  jmp @get_next_char
@no_more_input:
@send_buffer: 
  ldax  #transfer_buffer
  jsr tcp_send
  bcs @error_on_send
  jmp @main_polling_loop

@error_on_send:
  lda cursor_state
  sta $CC  
  
  ldax #transmission
  jmp print_error
  
reset_cursor:
  lda $cf ;0 means last cursor blink set char to be reversed
  beq @done
  lda $ce ;original value of cursor char
  ldx $287  ;original colour
  ldy #$0 ;blink phase
  sty $cf
  jsr $ea13 ;restore char & colour
@done:
  rts
netcat_callback: 
  jsr reset_cursor
  lda tcp_inbound_data_length+1
  cmp #$ff
  bne @not_eof
  lda #0
  sta connection_state
  rts
@not_eof:
  
  ldax tcp_inbound_data_ptr
  stax temp2
  lda tcp_inbound_data_length
  sta buffer_length
  lda tcp_inbound_data_length+1
  sta buffer_length+1
  
@next_byte:
  lda $cb ;current key pressed
  cmp #$18  ;RUN/STOP?
  beq @finished

  ldy #0
  lda (temp2),y
  ldx netcat_mode
  beq @no_transform
  jsr ascii_to_native
@no_transform:  
  jsr print_a
  inc temp2
  bne :+
  inc temp2+1
:  
  lda buffer_length+1
  beq @last_page
  lda buffer_length
  bne @not_end_of_page
  dec buffer_length+1
@not_end_of_page:  
  dec buffer_length  
  jmp @next_byte
@last_page:
  dec buffer_length
  beq @finished
  
  jmp @next_byte

@finished:  
  
  rts


tcpconnect_keyword:
  ldax #tcpconnect_callback
  stax tcp_callback  
  jmp make_tcp_connection

tcpconnect_callback:
  
  ldax #transfer_buffer
  stax  copy_dest
  ldax  tcp_inbound_data_ptr
  stax  copy_src
  lda   tcp_inbound_data_length
  ldx   tcp_inbound_data_length+1  
  beq @short_packet
  cpx #$ff
  bne @not_end_packet
  lda #0
  sta connection_state
  rts
@not_end_packet:
  lda #$ff
@short_packet:

set_input_string:
  pha
  lda #'I'
  ldx #'N'+$80 
  jsr find_var
  ldy #0
  pla
  pha
  sta (VARPNT),y
  iny
  lda #<transfer_buffer
  sta (VARPNT),y
  iny
  lda #>transfer_buffer
  sta (VARPNT),y  
  pla
  beq :+
  ldx #0
  jsr copymem
:  
  rts

poll_keyword:
  lda #0
  jsr set_input_string
  jsr set_connection_state
  jsr ip65_process
  lda ip65_error
  beq @no_error
  jmp set_error
@no_error:
  jmp set_connection_state

tcplisten_keyword:
  lda #0
  sta connection_state
  sta ip65_error
  ldax #tcpconnect_callback
  stax tcp_callback  
  jsr get_integer
  jsr tcp_listen
  bcs :+
  inc connection_state
:  
  jmp set_connection_state

tcpsend_keyword:
  jsr extract_string
  ldy param_length
  sty tcp_send_data_len
  ldy #0
  sty tcp_send_data_len+1
  ldax #transfer_buffer
  jsr tcp_send
  jmp set_connection_state

tcpclose_keyword:
  lda #0
  sta connection_state
  jsr tcp_close
  jmp set_connection_state
  
tcpblat_keyword:

  jsr extract_string
  
  ldx  #<transfer_buffer
  ldy #>transfer_buffer
  lda param_length
  jsr SETNAM
  lda #$02      ; file number 2
  ldx $BA       ; last used device number
  bne @skip
  ldx #$08      ; default to device 8
@skip:
  ldy #$02      ; secondary address 2
  jsr SETLFS
  jsr OPEN
  bcs @error    ; if carry set, the file could not be opened
  ldx #$02      ; filenumber 2
  jsr CHKIN
  ldy #$00
@loop:   
  jsr READST
  bne @eof          ; either EOF or read error
  jsr CHRIN
  sta transfer_buffer,y
  iny 
  bne @loop
  ldax #$100
  stax  tcp_send_data_len  
  ldax  #transfer_buffer
  jsr tcp_send
  bcs @error_stored
  ldy #0
  jmp @loop
@eof:
  and #$40      ; end of file?
  beq @readerror
  lda #$00
  sty  tcp_send_data_len
  sta  tcp_send_data_len+1
  ldax  #transfer_buffer
  jsr tcp_send
  bcs @error_stored
  
@close:
  lda #0
@store_error:  
  sta ip65_error
@error_stored:      
  lda #$02      ; filenumber 2
  jsr CLOSE        
  ldx #$00      ; filenumber 0 = keyboard
  jsr CHKIN ;keyboard now input device again
  jmp set_error
  
@error:
  lda #KPR_ERROR_DEVICE_FAILURE
  jmp @store_error
@readerror:
  lda #KPR_ERROR_FILE_ACCESS_FAILURE
  jmp @store_error

evaluate:
  lda $00  
  sta $0D ;set string flag to not string
  jsr CHRGET
  cmp #$E3  ; PING keyword
  bne @done
  
  jsr CHRGET    ;take PING command off stack
  
  ldax  #icmp_echo_ip
  jsr get_ip_parameter  
  lda #$00  
  sta $0D ;set string flag to not string

  bcs @error
  jsr   icmp_ping
  bcc @no_error
@error:  
  lda #$ff
  tax
@no_error:
  tay
  txa
  jmp $D395 ;signed 16 bit number to floating point
  rts
  
@done: 
  jsr CHRGOT  
  jmp $CE8D ;inside original EVAL routine
  
.rodata
vectors:
	.word crunch	
	.word list
	.word execute
  .word evaluate
; Keyword list
; Keywords are stored as normal text,
; followed by the token number.
; All tokens are >$80,
; so they easily mark the end of the keyword
hexdigits:
.byte "0123456789ABCDEF"

pinging:
.byte"PINGING ",0
interface_type:
.byte $12,"INTERFACE",$92,13,0

mac_address_msg:
.byte $12,"MAC ADDRESS",$92,13,0

ip_address_msg:
.byte $12,"IP ADDRESS",$92,13,0

netmask_msg:
.byte $12,"NETMASK",$92,13,0

gateway_msg:
.byte $12,"GATEWAY",$92,13,0
  
dns_server_msg:
.byte $12,"DNS SERVER",$92,13,0

dhcp_server_msg:
.byte $12,"DHCP SERVER",$92,13,0

tftp_server_msg:
.byte $12,"TFTP SERVER",$92,13,0

address_resolution:
.byte "ADDRESS RESOLUTION",0

get_msg:
.byte "GETTING ",0
put_msg:
.byte "PUTTING ",0

tftp:
.byte "TFTP",0
dhcp:
.byte "DHCP",0

connect:
.byte "CONNECT",0

transmission:
.byte "TRANSMISSION",0

error:
.byte " ERROR $",0

disconnected:
.byte 13,"DIS"
connected_msg:
.byte "CONNECTED",13,0

keywords:                    
  .byte "IF",$E0  ;our dummy 'IF' entry takes $E0
	.byte "IPCFG",$E1
	.byte "DHCP",$E2
  .byte "PING",$E3
  .byte "MYIP",$E4
  .byte "NETMASK",$E5
  .byte "GATEWAY",$E6
  .byte "DNS",$E7
  .byte "TFTP",$E8
  .byte "TF",$A1,$E9  ;TFGET - BASIC will replace GET with A1 
  .byte "TFPUT",$EA
  .byte "NETCAT",$EB
  .byte "TCPC",$91,"NECT",$EC ; TCPCONNECT - BASIC will replace ON with $91
  .byte "POLL",$ED
  .byte "TCP",$9B,"EN",$EE ;TCPLISTEN - BASIC will replace LIST with $9b
  .byte "TCPS",$80,$EF  ;TCPSEND - BASIC will replace END with $80
  .byte "TCP",$A0,$F0  ;TCPLOSE - BASIC will replace CLOSE with $A0
  .byte "TCPBLAT",$F1
  .byte "MAC",$F2
	.byte $00					;end of list
HITOKEN=$F3

;
; Table of token locations-1
;
token_routines:
E0:	.word if_keyword-1
E1:	.word ipcfg_keyword-1
E2: .word dhcp_keyword-1
E3: .word ping_keyword-1
E4: .word myip_keyword-1
E5: .word netmask_keyword-1
E6: .word gateway_keyword-1
E7: .word dns_keyword-1
E8: .word tftp_keyword-1
E9: .word tfget_keyword-1
EA: .word tfput_keyword-1
EB: .word netcat_keyword-1
EC: .word tcpconnect_keyword-1
ED: .word poll_keyword-1
EE: .word tcplisten_keyword-1
EF: .word tcpsend_keyword-1
FO: .word tcpclose_keyword-1
F1: .word tcpblat_keyword-1
F2: .word mac_keyword-1

.segment "SELF_MODIFIED_CODE"


jmp_crunch: .byte $4C          ;JMP
oldcrunch: 	.res 2             ;Old CRUNCH vector
oldlist:	.res 2             
oldexec:	.res 2           
oldeval: .res 2
emit_a:
current_output_ptr=emit_a+1
  sta $ffff
  inc string_length
  inc current_output_ptr
  bne :+
  inc current_output_ptr+1
:  
  rts


.bss
netcat_mode: .res 1
bytes_read: .res 2
string_length: .res 1
param_length: .res 1
ip_string:  .res 15 
netmask_string:  .res 15 
dns_string:  .res 15 
gateway_string:  .res 15 
 temp_bin: .res 1
temp_bcd: .res 2
ping_counter: .res 1
string_buffer: .res 128
transfer_buffer: .res 256
file_opened: .res 1
connection_state: .res 1
netcat_timeout: .res 1
buffer_length: .res 2
cursor_state: .res 1
