;a simple NETBIOS over TCP server
;aka "Common Internet File System"
;
; refs: RFC1001, RFC1002, "Implementing CIFS" - http://ubiqx.org/cifs/

.include "../inc/common.i"

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.export cifs_l1_encode
.export cifs_l1_decode
.importzp	copy_src

;given an ASCII (or PETSCII) hostname, convert to
;canonical 'level 1 encoded' form.
;
;only supports the default scope (' ' : 0x20)
;inputs: 
; AX: pointer to null terminated hostname to be encoded
;outputs:
; AX: pointer to decoded hostname
cifs_l1_encode:
	stax copy_src
	lda #0
	tax
	sta hostname_buffer+32
@empty_buffer_loop:	
	lda	#$43
	sta	hostname_buffer,x
	inx
	lda #$41
	sta	hostname_buffer,x
	inx
	cpx	#$20
	bmi	@empty_buffer_loop
	ldy	#0
	ldx	#0
@copy_loop:

	lda	(copy_src),y
	beq	@done
	lsr
	lsr
	lsr
	lsr
	clc
	adc #$41
	sta	hostname_buffer,x

	inx
	lda	(copy_src),y
	and #$0F
	clc
	adc #$41
	sta	hostname_buffer,x
	inx
	iny
	cpx	#$1D	
	bmi	@copy_loop
@done:	
	ldax #hostname_buffer
	rts
	
;given a 'level 1 encoded' hostname, decode to ASCII .
;
;inputs: 
; AX: pointer to encoded hostname to be decoded
;outputs:
; AX: pointer to decoded hostname (will be 16 byte hostname, right padded with spaces, nul terminated)
cifs_l1_decode:
	stax copy_src
	ldy	#0
	ldx	#0
@decode_loop:
	lda	(copy_src),y
	sec
	sbc	#$41
	asl
	asl
	asl
	asl
	sta hi_nibble
	iny
	lda	(copy_src),y
	sec
	sbc	#$41
	clc
	adc	hi_nibble
	sta	hostname_buffer,x
	iny
	inx
	cpx	#$10
	bmi	@decode_loop
	lda	#0
	sta	hostname_buffer,x
	ldax #hostname_buffer
	rts

	rts

	
.bss
hostname_buffer:	
	.res 33
hi_nibble: .res 1
;-- LICENSE FOR cifs.s --
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
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
