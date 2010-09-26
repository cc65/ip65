
.include "../inc/common.i"
.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.import ip65_init
.import dhcp_init
.import tcp_connect
.import dns_resolve
.import	print_a

.importzp copy_src
.importzp copy_dest
pptr=copy_src

ILOAD=$330
ISAVE=$332

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
	
;	jsr	ip65_init
	bcs	:+
	jsr	dhcp_init
:	
	ldax ILOAD
	cpx #>load_handler
	bne	@not_installed
	ldax #already_installed
	jsr	print
	jmp	@done
@not_installed:
	stax old_load_vector	
	ldax #load_handler
	stax ILOAD
	ldax #installed
	jsr	print

@done:	
	jsr	swap_basic_in

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
installed: .byte "V1541 INSTALLED",0

already_installed: .byte "V1541 ALREADY INSTALLED",0
.code

load_dev_2:
	inc $d020
	clc
	jmp	swap_basic_in


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

	
.segment "CODESTUB"

swap_basic_out:
	lda $01
	and #$FE
	sta $01
	rts

swap_basic_in:
	lda $01
	ora #$01
	sta $01
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
	