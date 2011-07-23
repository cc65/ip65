
;.include "../inc/common.i"
;.import cfg_get_configuration_ptr
;.include "../inc/commonprint.i"
;
;.include "../drivers/w5100.i"


WIZNET_BASE=$DE04
WIZNET_MODE_REG = WIZNET_BASE
WIZNET_ADDR_HI = WIZNET_BASE+1
WIZNET_ADDR_LO = WIZNET_BASE+2
WIZNET_DATA_REG = WIZNET_BASE+3

TEST_LOOPS=$FF

TX_BUFFER_START_PAGE=$40

TIMER_POSITION_ROW=6
TIMER_POSITION_COL=15
TIMER_POSITION=$400+TIMER_POSITION_ROW*40+TIMER_POSITION_COL
LAST_PROMPT_POSITION=$400+15*40+9

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


.zeropage
pptr: .res 2

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

	;set funky colours
	lda #$06  ;
    sta $D020 ;border
    lda #$00	;dark blue
    sta $D021 ;background

	ldax #banner
	jsr	print

	lda #0
	sta	clockport_mode
  	lda $de01
	ora #1			;turn on clockport
	sta $de01


	lda #$80  ;reset
	sta WIZNET_MODE_REG
	lda WIZNET_MODE_REG
	beq @reset_ok
	          	;writing a byte to the MODE register with bit 7 set should reset.
				;after a reset, mode register is zero
				;therefore, if there is a real W5100 at the specified address,
				;we should be able to write a $80 and read back a $00
@error:				
	ldax #not_found
	jsr	print
	lda #>WIZNET_MODE_REG
	jsr	print_hex
	lda #<WIZNET_MODE_REG
	jsr	print_hex
	jsr	print_cr	
	
;	jmp	$e37b
	jmp	@after_mac
				
@reset_ok:				
	lda #$11  ;set indirect mode, with no autoinc, no auto PING
	sta WIZNET_MODE_REG
	lda WIZNET_MODE_REG
	cmp #$11
	bne	@error
				;make sure if we write to mode register without bit 7 set,
				;the value persists.
	
@w5100_found:

	ldax #w5100_found
	jsr	print
	lda #>WIZNET_MODE_REG
	jsr	print_hex
	lda #<WIZNET_MODE_REG
	jsr	print_hex
	
	lda	#$77	;selected by random roll of a fairly weighted dice
	sta $de06
	cmp	$de02	;do values written to $de06 show up at $de02?
	beq	@clockport
	ldax #direct
	jmp :+
@clockport:	
	inc clockport_mode
	ldax	#clockport
:	
	jsr	print
	jsr	print_cr	

	jsr	copy_mac_to_w5100
	bcc	@print_mac
	ldax #invalid_mac_checksum
	jsr print
	jmp	@after_mac
	
@print_mac:
	
	ldax #MAC
	jsr	print
	lda #$00
	sta	WIZNET_ADDR_HI
	lda	#$09		;00009 = local MAC addres
	sta	WIZNET_ADDR_LO

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
  	lda WIZNET_DATA_REG
  	jsr print_hex
  	inc WIZNET_ADDR_LO
  	iny
  	cpy #06
  	bne @one_mac_digit

@after_mac:

	;set up to keep the timer updated
	lda #0
	sta update_clock
	ldax	$314	;old tick_handler
	stax	old_tick_handler
	ldax	#tick_handler
	sei
	stax	$314
	cli
	jsr reset_clock


	ldax #test_duration
	jsr print

	ldax #test_0
	jsr	print

	ldax #test_1
	jsr	print
	ldax #test_2
	jsr	print
	ldax #test_3
	jsr	print

	ldax #prompt
	jsr	print
	lda	clockport_mode
	bne	main
	ldax #test_4
	jsr	print
	ldax #test_5
	jsr	print
	lda	#$35
	sta	LAST_PROMPT_POSITION
main:	
	lda	#0
	sta	update_clock

	jsr get_key
	and #$7F		;ignore shift key

	cmp #' '
	bne	@not_space
	jsr reset_clock
@loop_test:	
	jsr	do_test_0
	bcs	main
	jsr	do_test_1
	bcs	main
	jsr	do_test_2
	bcs	main
	jsr	do_test_3
	bcs	main
	jsr	get_key_if_available
	bne	main
	jmp	@loop_test
@not_space:
	cmp #'0'
	bne	@not_0
	jsr reset_clock
	jsr	do_test_0
	jmp	main
@not_0:
	cmp #'1'
	bne	@not_1
	jsr reset_clock
	jsr	do_test_1
	jmp	main
@not_1:
	cmp #'2'
	bne	@not_2
	jsr reset_clock
	jsr	do_test_2
	jmp	main
	
@not_2:
	cmp #'3'
	bne	@not_3
	jsr reset_clock
	jsr	do_test_3
	jmp	main
@not_3:
	ldy clockport_mode
	bne	@not_valid_key

	cmp #'4'
	bne	@not_4
	jsr reset_clock
	jsr	do_test_4
	jmp	main
@not_4:

	cmp #'5'
	bne	@not_5
	jsr reset_clock
	jsr	do_test_5
	jmp	main
@not_5:

@not_valid_key:
  	lda $cb ;current key pressed
 	cmp #$3F
	beq	:+
	jmp main
:	
	jmp return_to_basic

	
failed:
	lda #$02
	sta $d020
	sec
	rts

	
do_test_0:

	lda	#0
	sta address_inc_mode

	ldax #test_0
	jsr	print
	lda #$11  ;set indirect mode, with no autoinc, no auto PING
	jmp set_address_mode
	
do_test_1:

	lda	#0
	sta	intersperse_address_reads
	lda	#1
	sta address_inc_mode

	ldax #test_1
do_w5100_test:	
	jsr	print
	lda #$13  ;set indirect mode, with autoinc, no auto PING
set_address_mode:	
	
	sta WIZNET_MODE_REG
	lda #$06  ;
    sta $D020 ;border
	
	jsr	w5100_access_test
	bcs	failed
ok:	
	ldax	#OK
	jsr	print
	clc
	rts

do_test_2:

	lda	#1
	sta	intersperse_address_reads
	sta address_inc_mode

	ldax #test_2
	jmp do_w5100_test


do_test_3:
	lda #$06  ;
    sta $D020 ;border

	ldax #test_3
	jsr	print
	sei
	ldax	#nmi_handler
	stax	$318
	cli
	clc
	
	lda	#1
	sta	update_clock

	lda #$11  ;set indirect mode, with no autoinc, no auto PING
	sta WIZNET_MODE_REG

	;set up the W5100 to trigger an interrupt
	lda #1
	lda #$00
	sta	WIZNET_ADDR_HI
	lda	#$16		;00016 = interrupt mask register
	sta	WIZNET_ADDR_LO
	lda #$04	;enable interruopt on socket 2 event
	sta WIZNET_DATA_REG
	lda	#$17		;retry period
	sta	WIZNET_ADDR_LO
	lda #$00	;retry period high byte
	sta WIZNET_DATA_REG
	lda	#$18		;retry period
	sta	WIZNET_ADDR_LO
	lda #$01	;retry period low byte
	sta WIZNET_DATA_REG

	lda	#$19		;retry count
	sta	WIZNET_ADDR_LO
	lda #$01	;trigger timeout after single attempt
	sta WIZNET_DATA_REG
	

	lda #$06		;06xx = socket 2
	sta	WIZNET_ADDR_HI
	lda	#$00		;socket mode register
	sta	WIZNET_ADDR_LO
	lda #$01	;TCP socket
	sta WIZNET_DATA_REG
	
	lda #$02		;$0602 = interrupt register, socket 2
	sta	WIZNET_ADDR_LO
	lda #$FF
	sta WIZNET_DATA_REG

	lda	#0
	sta	timeout_count

@trigger_one_timeout:
	lda	#0
	sta	got_nmi
	;clear interrupt register	
	lda #$02		;$0602 = interrupt register, socket 2
	sta	WIZNET_ADDR_LO
	lda #$FF
	sta WIZNET_DATA_REG


	lda #$01		;$0601 = command register, socket 2
	sta	WIZNET_ADDR_LO
	lda #$04		;connect
	sta WIZNET_DATA_REG

@loop_till_timeout:
	lda #$02		;$0602 = interrupt register, socket 2
	sta	WIZNET_ADDR_LO
	lda WIZNET_DATA_REG
	beq	@loop_till_timeout
	lda got_nmi
	bne	@ok
	jmp	failed
@ok:	
	ldax #reset_cursor
	jsr	print

	lda timeout_count	
	jsr	print_hex
	inc timeout_count
	bne	@trigger_one_timeout
	jmp ok

nmi_handler:
;	inc	$d020
	inc got_nmi
	rti
	
do_test_4:
	
	lda #$06  ;
    sta $D020 ;border

	ldax #test_4
	jsr	print
	
	lda	#1
	sta	update_clock

	ldy	#$0
@bank_loop:
	lda	 #$64
	sta	$de01 ;go to 'shut up' mode
	sta	$4000	;this should be in RAM
	
	sta $de02 ;leave 'shut up' mode
	sta	$de0e  ;set both banking bits to 0
	lda	#$00
	sta	$4000	;this should be bank 0
	
	sta	$de0a  ;set banking bit 0 to 1
	lda	#$01
	sta	$4000	;this should be bank 1

	sta	$de0e  ;set both banking bits to 0
	lda	#$02
	sta	$de0c  ;set banking bit 1 to 0
	lda	#$02
	sta	$4000	;this should be bank 2
	
	sta	$de0a  ;set banking bit 0 to 1
	lda	#$03
	sta	$4000	;this should be bank 3

	lda	 #$64
	sta	$de01 ;go to 'shut up' mode
	cmp	$4000	;this should be in RAM
	bne	@banking_error
	
	sta $de02 ;leave 'shut up' mode
	sta	$de0e  ;set both banking bits to 0
	lda	#$00
	cmp	$4000	;this should be in bank 0
	bne	@banking_error
	
	sta	$de0a  ;set banking bit 0 to 1
	lda	#$01
	cmp	$4000	;this should be in bank 1
	bne	@banking_error

	sta	$de0e  ;set both banking bits to 0
	lda	#$02
	sta	$de0c  ;set banking bit 1 to 0
	lda	#$02
	cmp	$4000	;this should be in bank 2
	bne	@banking_error
	
	sta	$de0a  ;set banking bit 0 to 1
	lda	#$03
	cmp	$4000	;this should be in bank 3
	bne	@banking_error
	tya
	pha
	ldax #reset_cursor
	jsr	print
	pla	
	pha
	jsr	print_hex
	pla
	tay
	iny
	bne	@bank_loop
	jmp ok

		
@banking_error:
	pha
	ldax #reset_cursor
	jsr	print
	pla
	jsr	print_hex
	sec
	rts
do_test_5:
	;FIXME
return_to_basic:
	ldax #after_prompt
	jsr print
	sei
	ldax	old_tick_handler
	stax	$314	;old tick_handler
	ldax 	#$FE47
	stax 	$318
	cli
	jmp $e37b

w5100_access_test:
	
	lda	#1
	sta	update_clock

	lda #0
	sta	loop_count

@next_loop:
	lda	loop_count
	and	#$1f
	clc
	adc #TX_BUFFER_START_PAGE
	sta	test_page

	lda	test_page
	sta	WIZNET_ADDR_HI

	lda	#$00
	sta	WIZNET_ADDR_LO

	ldax #reset_cursor
	jsr	print
	lda	loop_count
	jsr	print_hex

	
	lda #0
	sta	byte_counter
@write_one_byte:
	lda	byte_counter
	sta	WIZNET_DATA_REG
	lda intersperse_address_reads
	beq :+
	lda	WIZNET_ADDR_LO	;see if we can force a glitch!
:	

	lda address_inc_mode
	bne :+
	inc	WIZNET_ADDR_LO	;see if we can force a glitch!
:	

	inc byte_counter
	bne	@write_one_byte

	;reset the pointer to start of this page

	lda	test_page
	sta	WIZNET_ADDR_HI

	lda	#$00
	sta	WIZNET_ADDR_LO

	ldx #0
@test_one_byte:
	lda WIZNET_DATA_REG
	sta last_byte
	cpx	last_byte
	beq	@ok
	sec
	rts	
@ok:
	lda address_inc_mode
	bne :+
	inc	WIZNET_ADDR_LO	;see if we can force a glitch!
:	

	inx
	bne	@test_one_byte

@after_test:
	inc	loop_count
	lda	loop_count
	cmp	#<(TEST_LOOPS+1)
	beq	:+
	jmp	@next_loop
:	

@exit:	
	clc
	rts

	

reset_clock:
	lda #0
	sta tick_counter
	sta $dc0b
	sta $dc0a
	sta $dc09
	sta $dc08
	rts
;---------------------
;standard printing helper routines
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

print_a=$ffd2

print_cr:
	lda #13
	jmp	print_a

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

tick_handler:
	lda	update_clock
	beq	@done
	inc tick_counter
	lda	tick_counter
	cmp	#10
	bne	@done
	lda	#0
	sta	tick_counter
	jsr	show_timer
@done:	
	jmp	(old_tick_handler)
	
show_timer:
	lda	$dc08	;read 10ths of seconds in case the time was latched
	lda $dc0b	;hours as BCD
	bpl @not_pm
	and $7f		;clear bit 7
	clc
	adc	#$12
@not_pm:	
	pha
	lsr
	lsr
	lsr
	lsr
	jsr	make_digit
	sta	TIMER_POSITION
	pla
	jsr	make_digit
	sta	TIMER_POSITION+1
	lda #':'
	sta	TIMER_POSITION+2
	lda	$dc0a	;minutes as BCD
	pha
	lsr
	lsr
	lsr
	lsr
	jsr	make_digit
	sta	TIMER_POSITION+3
	pla
	jsr	make_digit
	sta	TIMER_POSITION+4
	lda #':'
	sta	TIMER_POSITION+5
	
	lda	$dc09   ;seconds as BCD
	pha
	lsr
	lsr
	lsr
	lsr
	jsr	make_digit
	sta	TIMER_POSITION+6
	pla

	jsr	make_digit
	sta	TIMER_POSITION+7
	rts

make_digit:
	and #$0f
	clc
	adc	#$30
	rts

get_key_if_available=$f142 ;not officially documented - where F13E (GETIN) falls through to if device # is 0 
get_key:
  jsr get_key_if_available
  beq get_key
  rts


copy_mac_to_w5100:
	TEMP_BUFFER=$100	;we will execute directly in the bottom part of the stack
	RELOC_BUFFER=TEMP_BUFFER+08	;reserve 8 bytes of data
	TEMP_PTR=$39			;somewhere safe-ish in zero page
	ldy	#reloc_length
@reloc_one_byte:	
	lda	reloc_start,y
	sta	RELOC_BUFFER,y
	dey
	bpl	@reloc_one_byte
	jsr	RELOC_BUFFER
;MAC + flags + checksum should now be in TEMP_BUFFER

	;validate the checksum
	clc
	ldy	#0
	tya
@checksum_loop:
	asl
	adc	TEMP_BUFFER,y
	iny
	cpy	#7					;6 byte MAC address plus 1 byte flag
	bne @checksum_loop
	cmp	TEMP_BUFFER+7		
	beq	@checksum_ok
	sec
	rts
@checksum_ok:	
	lda #$00
	sta	$de05	;w5100 address register high byte
	lda	#$09	;00009 = local MAC addres
	sta	$de06	;w5100 address register low byte
  	ldy #0
@write_one_mac_byte:
	lda	TEMP_BUFFER,y
  	sta $de07	;w5100 data register
  	inc $de06	;w5100 address register low byte
  	iny
  	cpy	#6
  	bne @write_one_mac_byte
	clc
	rts
	
reloc_start:
	lda	#$09	;00009 = local MAC addres
	sta	$de06	;w5100 address register low byte
	cmp	$de02	;do values written to $de06 show up at $de02?
	beq	@clockport	
				;we are in expansion port; so turn on ROM
	sta $de02 ;leave 'shut up' mode
	sta $de08  ;enable ROM
		
	lda	#$9F
	sta	TEMP_PTR+1
	lda	#$F8
	bne	:+

@clockport:
	lda	#$DE
	sta	TEMP_PTR+1
	lda	#$08
:	
	sta	TEMP_PTR

;as soon as we access a W5100 register ($de04..$de07)
;we disable the ROM if we are in expansion port mode
;so we have to copy the MAC from the ROM on to the stack 
;before we start to write it to the W5100
 	ldy #7
@read_one_mac_byte:
	lda	(TEMP_PTR),y
	sta	TEMP_BUFFER,y
  	dey
  	bpl @read_one_mac_byte
;	
;go back to shutup mode	by writing to $de01
  	lda $de01
	ora #1			;turn on clockport
	sta $de01	
	rts
reloc_length=*-reloc_start

  
.data

banner:
.byte $93 ;CLS
.byte $9a;
.byte $0d,"RR-NET MK3 DIAGNOSTICS 0.27"

.include "timestamp.i"
.byte $0d
.byte 0

test_duration:
.byte $13	;home
.byte  $11,$11,$11,$11,$11,$11
.byte "TEST DURATION: 00:00:00"
.byte $0d
.byte 0

OK:
	.byte 157,157,"OK ",0

test_0:
.byte $13	;home
.byte  $11,$11,$11,$11,$11,$11,$11,$11
.byte "0) W5100 MEMORY ACCESS 0 :   "
.byte 0

test_1:
.byte $13	;home
.byte  $11,$11,$11,$11,$11,$11,$11,$11,$11
.byte "1) W5100 MEMORY ACCESS 1 :   "
.byte 0
test_2:
.byte $13	;home
.byte  $11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte "2) W5100 MEMORY ACCESS 2 :   "
.byte 0
test_3:
.byte $13	;home
.byte  $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte "3) NMI TEST              :   "
.byte 0
test_4:
.byte $13	;home
.byte  $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte "4) SRAM BANKING TEST     :   "
.byte 0
test_5:
.byte $13	;home
.byte  $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte "5) SRAM RD/WR TEST       :   "
.byte 0

prompt:
.byte $13	;home
.byte  $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte "PRESS 0..3 TO RUN A SINGLE TEST",13
.byte "SPACE TO CYCLE ALL TESTS",13
.byte 0
after_prompt:
.byte $13	;home
.byte  $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte 0
not_found: .byte "NO "
w5100_found: .byte "W5100 FOUND AT $",0
error_offset: .byte 13,"OFFSET $",0
was: .byte " WAS $",0
reset_cursor: .byte 157,157,0
clockport: .byte " [CLOCKPORT]",0
direct: .byte " [DIRECT]",0
MAC: .byte "MAC: ",0
invalid_mac_checksum: .byte"INVALID MAC CHECKSUM",13,0
.bss
last_byte: .res 1
loop_count: .res 1
byte_counter: .res 1
current_register:.res 1
current_byte_in_row: .res 1
test_page: .res 1
last_row: .res 1
intersperse_address_reads: .res 1
old_tick_handler: .res 2
update_clock: .res 1
tick_counter: .res 1
timeout_count: .res 1
got_nmi: .res 1
clockport_mode: .res 1
address_inc_mode: .res 1