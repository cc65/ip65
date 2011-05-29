
;.include "../inc/common.i"
;.import cfg_get_configuration_ptr
;.include "../inc/commonprint.i"
;
;.include "../drivers/w5100.i"



WIZNET_MODE_REG = $DE04
WIZNET_ADDR_HI = $DE05
WIZNET_ADDR_LO = $DE06
WIZNET_DATA_REG = $DE07

TEST_LOOPS=$1F

TX_BUFFER_START_PAGE=$40


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

    lda $de01
    eor #$01
    sta $de01		;enable clock port


	lda #147		;cls
	jsr	print_a		
	lda #142			;go to upper case mode
	jsr	print_a		
	lda #$80  ;reset
	sta WIZNET_MODE_REG
	lda WIZNET_MODE_REG
	beq @reset_ok
	jmp @error	;writing a byte to the MODE register with bit 7 set should reset.
				;after a reset, mode register is zero
				;therefore, if there is a real W5100 at the specified address,
				;we should be able to write a $80 and read back a $00
@reset_ok:				
	lda #$13  ;set indirect mode, with autoinc, no auto PING
	sta WIZNET_MODE_REG
	lda WIZNET_MODE_REG
	cmp #$13
	beq	@mode_persists
				;make sure if we write to mode register without bit 7 set,
				;the value persists.
	jmp	@error
@mode_persists:	

	ldax #w5100_found
	jsr	print
	jsr print_base_address
	
	lda	#0
	sta	intersperse_address_reads
@reset_test_loops:	
	
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

	
	
;	jmp @exit

	ldax #loop
	jsr	print
	lda loop_count
	jsr	print_hex
	
	lda #':'
	jsr	print_a
	jsr	print_wiz_address

	
	lda intersperse_address_reads
	beq @without
	ldax #with_address_reads
	jsr	print
	jmp :+
@without:
	ldax #without
	jsr	print
	ldax #address_reads
	jsr	print
:
	lda #0
	sta	byte_counter
@write_one_byte:
	lda	byte_counter
	sta	WIZNET_DATA_REG
	lda intersperse_address_reads
	beq :+
	lda	WIZNET_ADDR_LO	;see if we can force a glitch!
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
	txa
	pha
	ldax #error_offset
	jsr	print
	pla
	jsr	print_hex
	ldax #was
	jsr	print
	lda last_byte
	jsr	print_hex

	jsr	print_cr
	

	lda	test_page
	sta	WIZNET_ADDR_HI

	ldy #$00	;# of bytes to print
	jsr dump_wiznet_register_page

	jmp @exit
	
@ok:	
	inx
	bne	@test_one_byte

@after_test:
	jsr	print_cr		
	inc	loop_count
	lda	loop_count
	cmp	#<(TEST_LOOPS+1)
	beq	:+
	jmp	@next_loop
:	

	lda intersperse_address_reads
	bne	@exit
	inc intersperse_address_reads
	jmp @reset_test_loops
	
@exit:	

	jmp	$e37b

@error:
	ldax #not_found
	jsr	print
	jsr	print_base_address
	
	jmp	@exit
	
print_base_address:	
	lda #>WIZNET_MODE_REG
	jsr	print_hex
	lda #<WIZNET_MODE_REG
	jsr	print_hex
	jmp	print_cr	

print_wiz_address:
	lda #'$'
	jsr	print_a
	lda WIZNET_ADDR_HI
	jsr	print_hex
	lda WIZNET_ADDR_LO
	jmp	print_hex


dump_wiznet_register_page:

  sta WIZNET_ADDR_HI
  sty last_row
  ldx #$00
  stx WIZNET_ADDR_LO
  stx byte_counter

  lda #$13  ;set indirect mode, with autoinc, no auto PING
  sta WIZNET_MODE_REG

  jsr print_cr

@one_row:
  jsr print_wiz_address
  lda #':'
  jsr print_a

  lda #$0
  sta current_byte_in_row
@dump_byte:


  lda WIZNET_DATA_REG
  jsr print_hex
 
  inc current_byte_in_row
  inc byte_counter
  lda current_byte_in_row
  cmp #$08
  bne :+

  lda #' '
  jsr print_a
  jmp @dump_byte
 :
  cmp #$10
  bne @dump_byte
  
  jsr print_cr
  lda byte_counter
  cmp last_row
  beq @done
  
  jmp @one_row
@done:
  jsr print_cr
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

.data

loop: .byte "TEST $",0
not_found: .byte "NO "
w5100_found: .byte "W5100 FOUND AT $",0
error_offset: .byte 13,"OFFSET $",0
was: .byte " WAS $",0

without: .byte " [WITHOUT",0
with_address_reads: .byte " [WITH"
address_reads: .byte " ADDRESS READS]",0
.bss
last_byte: .res 1
loop_count: .res 1
byte_counter: .res 1
current_register:.res 1
current_byte_in_row: .res 1
test_page: .res 1
last_row: .res 1
intersperse_address_reads: .res 1
