; utility routine to copy memory


	.export copymem
	.exportzp copy_src
	.exportzp copy_dest


	.segment "IP65ZP" : zeropage

; pointers for copying
copy_src:	.res 2			; source pointer
copy_dest:	.res 2			; destination pointer


	.bss

end:		.res 1


	.code

;copy memory
;inputs:
; copy_src is address of buffer to copy from
; copy_dest is address of buffer to copy to
; AX = number of bytes to copy
;outputs: none
copymem:
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
