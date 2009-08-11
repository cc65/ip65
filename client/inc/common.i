.ifndef COMMON__I__
COMMON__I__ = 1
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


.macro phax
  pha
  txa
  pha
.endmacro

.macro plax
  pla
  tax
  pla
.endmacro

.endif