
.include "../inc/common.i"
;.include "../inc/commonprint.i"

VARTAB	=	$2D		;BASIC variable table storage
ARYTAB	=	$2F		;BASIC array table storage
FREETOP	=	$33		;bottom of string text storage area
MEMSIZ	=	$37		;highest address used by BASIC

SETNAM	=	$FFBD
SETLFS	=	$FFBA 
OPEN	=	$FFC0
CHKIN	=	$FFC6
READST	=	$FFB7     ; read status byte
CHRIN	=	$FFCF     ; get a byte from file
CLOSE	=	$FFC3
MEMTOP  = 	$FE25                          
TXTPTR  = $7A            ;BASIC text pointer
IERROR  = $0300          
ICRUNCH = $0304          ;Crunch ASCII into token
IQPLOP  = $0306          ;List
IGONE   = $0308          ;Execute next BASIC token
                          
CHRGET  = $73            
CHRGOT  = $79            
CHROUT  = $FFD2          
GETBYT  = $B79E          ;BASIC routine
GETPAR  = $B7EB          ;Get a 16,8 pair of numbers
CHKCOM  = $AEFD          
NEW     = $A642          
CLR     = $A65E
NEWSTT	= $A7AE
                          
LINNUM   = $14            ;Number returned by GETPAR

crunched_line      = $0200          ;Input buffer

.zeropage
temp:	.res 2
temp2:	.res 2

.segment "STARTUP"    ;this is what gets put at the start of the file on the C64
.word jump_table		; load address
jump_table:
  jmp init	              ; $4000 (PTR 16384) - vars io$,io%,er% should be created (in that order!) before calling
.code


;
;BASIC extensions derived from BLARG - http://www.ffd2.com/fridge/programs/blarg/blarg.s
;

init:
	ldx	#5           ;Copy CURRENT vectors
@copy_old_vectors_loop:
	lda ICRUNCH,x
	sta	oldcrunch,x
	dex
	bpl	@copy_old_vectors_loop


	ldx	#5           ;Copy CURRENT vectors
install_new_vectors_loop:
	lda vectors,x
	sta	ICRUNCH,x
	dex
	bpl	install_new_vectors_loop
	rts

;
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
	lda	keywords,y
	bmi	@out
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
	jmp $A700        ;Normal exit


execute:
                          
;
; EXECUTE -- if this is one of my
; tokens, then execute it.
;
;	jmp (oldexec)

	jsr	CHRGET
	php
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
	cmp	#0
	jmp $A7E7
              
goober:
	inc $d020
	rts


.rodata
vectors:
	.word crunch	
	.word list
	.word execute
	
.data


jmp_crunch: .byte $4C          ;JMP
oldcrunch: 	.res 2             ;Old CRUNCH vector
oldlist:	.res 2             
oldexec:	.res 2           


; Keyword list
; Keywords are stored as normal text,
; followed by the token number.
; All tokens are >$80,
; so they easily mark the end of the keyword

keywords:
	.byte "FIZZ",$E0
	.byte $00					;end of list
HITOKEN=$E1

;
; Table of token locations-1
; Subtract $E0 first
; Then check to make sure number isn't greater than NUMWORDS
;
token_routines:
E0:	.word goober-1