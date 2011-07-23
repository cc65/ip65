
.include "../inc/common.i"
print_a = $ffd2



.zeropage
cart_data_ptr:	.res 2
eeprom_ptr:	.res 2
pptr: .res 2
checksum_ptr: .res 2
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

	ldax #banner
	jsr	print
	cli
	
	;check if our data is a KIPPER image (with MAC at offset 0x18)
	lda  cart_data+9
	cmp	#'K'
	bne	@not_kipper
	lda  cart_data+10
	cmp	#'I'
	bne	@not_kipper
	lda  cart_data+11
	cmp	#'P'
	bne	@not_kipper
@loop:	
	ldax #found_kip
	jsr	print
	lda cart_data+$18
	sta cart_data+$1FF8
	lda cart_data+$19
	sta cart_data+$1FF9
	lda cart_data+$1A
	sta cart_data+$1FFA
	lda cart_data+$1B
	sta cart_data+$1FFB
	lda cart_data+$1C
	sta cart_data+$1FFC
	lda cart_data+$1D
	sta cart_data+$1FFD

	lda #0					;flag byte defaults to 0
	sta cart_data+$1FFE
	
	ldax #cart_data+$1FF8
	stax checksum_ptr
	
	clc
	ldy	#0
	tya
@checksum_loop:
	asl
	adc	(checksum_ptr),y
	iny
	cpy	#7					;6 byte MAC address plus 1 byte flag
	bne @checksum_loop
	
	sta cart_data+$1FFF
	jsr	print_hex
	jsr	print_cr
@not_kipper:	

	
	ldax #$8000
	stax eeprom_ptr

	;set up access to READ/WRITE external ROM
	
	lda #$37
	sta $01
	sta  $de02 ;leave 'shut up' mode
	sta $de08  ;enable ROM
	sta $de0a	;set banking bit 0
	sta $de0c	;set banking bit 1

	lda	$d011
	sta	old_d011
	and #$ef		;turn off bit 4
	sta	$d011
	jsr	turn_off_write_protect


	ldax #$8000
	stax eeprom_ptr

@reset_64_bytes:
	inc $d020	
	
	ldy	#0
@reset_1_byte:
	lda	#0
	sta	(eeprom_ptr),y
	iny
	cpy	#64
	bne @reset_1_byte
	jsr	poll_till_stable

	clc
	tya
	adc eeprom_ptr
	sta eeprom_ptr
	bcc	:+
	inc	eeprom_ptr+1
:
	
	lda eeprom_ptr+1
	cmp	#$A0
	bne	@reset_64_bytes			

;now validate the reset
	lda #$0
	sta	validation_counter
	lda	old_d011
	sta	$d011

	ldax #validating_reset
	jsr	print
	
@reset_validation_loop:
	ldax #$8000
	stax eeprom_ptr
	ldy #0
@reset_compare_loop:
	lda (eeprom_ptr),y
	bne	@reset_validation_error
	iny
	bne	@reset_compare_loop
	lda	 #'.'
	jsr	print_a

	inc	eeprom_ptr+1
	lda eeprom_ptr+1
	cmp	#$A0
	bne	@reset_compare_loop
	beq	@reset_ok
	@reset_validation_error:
	jmp	@validation_error
	
@reset_ok:	
	ldax #OK
	jsr	print
		

	lda	$d011
	and #$ef		;turn off bit 4
	sta	$d011


	ldax #cart_data
	stax cart_data_ptr
	ldax #$8000
	stax eeprom_ptr

@copy_64_bytes:
	inc $d020	
	
	ldy	#0
@copy_1_byte:
	lda	(cart_data_ptr),y
	sta	(eeprom_ptr),y
	iny
	cpy	#64
	bne @copy_1_byte
	jsr	poll_till_stable

	clc
	tya
	adc eeprom_ptr
	sta eeprom_ptr
	bcc	:+
	inc	eeprom_ptr+1
:
	clc
	tya
	adc cart_data_ptr
	sta cart_data_ptr
	bcc	:+
	inc	cart_data_ptr+1
:
	
	lda eeprom_ptr+1
	cmp	#$A0
	bne	@copy_64_bytes			

;now validate the data
	lda #$0
	sta	validation_counter
	lda	old_d011
	sta	$d011

	ldax #validating
	jsr	print
	
@validation_loop:
	ldax #cart_data
	stax cart_data_ptr
	ldax #$8000
	stax eeprom_ptr
	ldy #0
@compare_loop:
	lda (cart_data_ptr),y
	cmp	(eeprom_ptr),y
	bne	@validation_error
	iny
	bne	@compare_loop
	lda	 #'.'
	jsr	print_a

	inc	cart_data_ptr+1
	inc	eeprom_ptr+1
	lda eeprom_ptr+1
	cmp	#$A0
	bne	@compare_loop
	
	inc validation_counter
	lda	validation_counter
	cmp #$08
	bne @validation_loop
	ldax #ok
	jsr	print
	
	ldax #$8000
	stax eeprom_ptr

	jsr turn_on_write_protect	

	jmp	@exit_to_basic
	
@validation_error:
	sty	error_offset

	ldax #validation_error
	jsr	print
	lda eeprom_ptr+1
	jsr	print_hex
	lda eeprom_ptr
	jsr	print_hex
	ldax #offset
	jsr	print
	lda error_offset
	jsr print_hex
	jsr	print_cr
	

	ldax #wr
	jsr	print
	lda #0
	sta	byte_ptr
@wr_loop:
	ldy	byte_ptr
	lda (cart_data_ptr),y
	jsr	print_hex
	
	lda byte_ptr
	cmp	error_offset
	beq	:+
	inc	byte_ptr
	bne	@wr_loop
:	
	jsr	print_cr
	
	ldax #rd
	jsr	print
	lda #0
	sta	byte_ptr
@rd_loop:
	ldy	byte_ptr
	lda (eeprom_ptr),y
	jsr	print_hex
	lda byte_ptr
	cmp	error_offset
	beq	:+
	inc	byte_ptr
	bne	@rd_loop
:	
	jsr	print_cr
	
;if there is an error somewhere in the eeprom, but we have a valid 'CBM80' header bad things can happen
;so overwrite the signature bytes
	lda #$FF
	sta $8004
	sta $8005
	sta $8006
	sta $8007
	sta $8008
	
@exit_to_basic:	
	sei
	lda	old_d011
	sta	$d011
	rts	

turn_off_write_protect:
	;do the 'secret knock' to enable writes
	lda #$55
	sta $9c55
	lda #$aa
	sta $83aa
	lda #$01
	sta $9c55
	lda #$55
	sta $9c55
	lda #$aa
	sta $83aa
	lda #$04
	sta $9c55
	jmp	poll_till_stable

turn_on_write_protect:
	;do the 'secret knock' to disable writes

	lda #$55 
	sta $9c55 
	lda #$aa 
	sta $83aa 
	lda #$05 
	sta $9c55

poll_till_stable:
	ldax eeprom_ptr
	stax	@offset_1+1
	stax	@offset_2+1
	ldx	#$03
@poll_loop:
@offset_1:	
	lda	$8000	;address will get overwritten
@offset_2:	
	cmp	$8000	;address will get overwritten
	bne	poll_till_stable
	dex
	bne	@poll_loop
@done:
	rts


print_cr:
  lda #13
  jmp print_a

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

banner:
.byte 147	;cls
.byte 142	;upper case
.byte 13," RR-NET MK3 FLASHER V0.02"
.include "timestamp.i"
.byte 13
.byte 0
ok: .byte 13,"OK",13,0
validating: .byte 13,"CHECKING EEPROM DATA ",13,0
validation_error:
.byte 13,"VALIDATION ERROR : $",0
offset: .byte " OFFSET : $",0
OK: .byte 13,"OK",13,0
validating_reset: .byte "VALIDATING EEPROM RESET",13,0
rd: .byte "RD :",0
wr: .byte "WR :",0
found_kip:
.byte 13," KIP HEADER FOUND - RELOCATING MAC",13
.byte " CHECKSUM : $"
.byte 0
.bss
cart_data:	;this should point to where the cart data gets appended.
	.res $2000
	
error_offset: .res 1
byte_ptr: .res 1
old_d011: .res 1
validation_counter: .res 1
