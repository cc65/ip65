;
; Copyright (c) 2007, Adam Dunkels and Oliver Schmidt
; All rights reserved. 
;
; Redistribution and use in source and binary forms, with or without 
; modification, are permitted provided that the following conditions 
; are met: 
; 1. Redistributions of source code must retain the above copyright 
;    notice, this list of conditions and the following disclaimer. 
; 2. Redistributions in binary form must reproduce the above copyright 
;    notice, this list of conditions and the following disclaimer in the 
;    documentation and/or other materials provided with the distribution. 
; 3. Neither the name of the Institute nor the names of its contributors 
;    may be used to endorse or promote products derived from this software 
;    without specific prior written permission. 
;
; THIS SOFTWARE IS PROVIDED BY THE INSTITUTE AND CONTRIBUTORS ``AS IS'' AND 
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
; ARE DISCLAIMED.  IN NO EVENT SHALL THE INSTITUTE OR CONTRIBUTORS BE LIABLE 
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS 
; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
; SUCH DAMAGE. 
;
; This file is part of the Contiki operating system.
; 
; Author: Adam Dunkels <adam@sics.se>, Oliver Schmidt <ol.sc@web.de>
;
;---------------------------------------------------------------------

	.macpack	module
	module_header	_cs8900a

	; Driver signature
	.byte	$65, $74, $68	; "eth"
	.byte	$01		; Ethernet driver API version number

	; Ethernet address
mac:	.byte	$00, $0E, $3A	; OUI of Cirrus Logic
	.ifdef __C64__
	.byte	$64, $64, $64
	.endif
	.ifdef __C128__
	.byte	$28, $28, $28
	.endif
	.ifdef __APPLE2__
	.byte	$A2, $A2, $A2
	.endif
	.ifdef __ATARI__
	.byte	$A8, $A8, $A8
	.endif
	.ifdef __VIC20__
	.byte	$20, $20, $20
	.endif

	; Buffer attributes
bufaddr:.res	2		; Address
bufsize:.res	2		; Size

	; Jump table.
	jmp init
	jmp poll
	jmp send
	jmp exit

;---------------------------------------------------------------------

	.if DYN_DRV

	.zeropage
sp:	.res	2		; Stack pointer (Do not trash !)
reg:	.res	2		; Address of rxtxreg
ptr:	.res	2		; Indirect addressing pointer
len:	.res	2		; Frame length
cnt:	.res	2		; Frame length counter

	.else

	.include "zeropage.inc"
reg	:=	ptr1		; Address of rxtxreg
ptr	:=	ptr2		; Indirect addressing pointer
len	:=	ptr3		; Frame length
cnt	:=	ptr4		; Frame length counter

	.endif

;=====================================================================

	.ifdef __CBM__

	.rodata

	; Ethernet address
rrnet:	.byte	$28, $CD, $4C	; OUI of Individual Computers
	.byte	$FF		; Reserved for RR-Net

;---------------------------------------------------------------------

	.if .defined (__C64__) .or .defined (__C128__)
rxtxreg		:= $DE08
txcmd		:= $DE0C
txlen		:= $DE0E
isq		:= $DE00
packetpp	:= $DE02
ppdata		:= $DE04
	.endif

	.ifdef __VIC20__
rxtxreg		:= $9808
txcmd		:= $980C
txlen		:= $980E
isq		:= $9800
packetpp	:= $9802
ppdata		:= $9804
	.endif

;---------------------------------------------------------------------

	.code

init:
	; Activate C64 RR clockport in order to operate RR-Net
	; (RR config register overlays unused CS8900A ISQ register)
	lda isq+1
	ora #$01		; Set clockport bit
	sta isq+1

	; Check EISA registration number of Crystal Semiconductor
	; PACKETPP = $0000, PPDATA == $630E ?
	lda #$00
	tax
	jsr packetpp_ax
	lda #$63^$0E
	eor ppdata
	eor ppdata+1
	beq :+
	sec
	rts

	; "When the RR-Net MK3 is used in cartridge mode, the EEPROM will serve as a
	;  regular 8k ROM cartridge. It is used as a startup-ROM if the unit is plugged
	;  directly to a C64. The startup code will initialize the MAC address."
	; PACKETPP = $0158, PPDATA == RR-Net[0], RR-Net[1] ?
	; PACKETPP = $015A, PPDATA == RR-Net[2], RR-Net[3] ?
	; PACKETPP = $015C, AX = PPDATA
:	ldy #$58
:	tya
	jsr packetpp_a1
	lda ppdata
	ldx ppdata+1
	cpy #$58+4
	bcs copy
	cmp rrnet-$58,y
	bne :+
	txa
	cmp rrnet-$58+1,y
	bne :+
	iny
	iny
	bne :-			; Always

	; "If the RR-Net MK3 is connected to a clockport, then the last 4 bytes of the
	;  EEPROM are visible by reading the last 4, normally write-only, registers."
	; MAC_LO ^ MAC_HI ^ $55 == CHKSUM0 ?
:	lda txcmd		; MAC_LO
	eor txcmd+1		; MAC_HI
	eor #$55
	cmp txlen		; CHKSUM0
	bne reset

	; (CHKSUM0 + MAC_LO + MAC_HI) ^ $AA == CHKSUM1 ?
	clc
	adc txcmd		; MAC_LO
	clc
	adc txcmd+1		; MAC_HI
	eor #$AA
	cmp txlen+1		; CHKSUM1
	bne reset

	; "When both checksums match, the CS8900A should be initialized
	;  to use the MAC Address 28:CD:4C:FF:<MAC_HI>:<MAC_LO>."
	; AX = MAC_LO, MAC_HI
	lda txcmd		; MAC_LO
	ldx txcmd+1		; MAC_HI

	; MAC[4], MAC[5] = AX
	; MAC[2], MAC[3] = RR-Net[2], RR-Net[3]
	; MAC[0], MAC[1] = RR-Net[0], RR-Net[1]
copy:	ldy #$04
	bne :++			; Always
:	lda rrnet,y
	ldx rrnet+1,y
:	sta mac,y
	txa
	sta mac+1,y
	dey
	dey
	bpl :--

	.endif

;=====================================================================

	.ifdef __APPLE2__

	.rodata

fixup:	.byte	fixup02-fixup01, fixup03-fixup02, fixup04-fixup03
	.byte	fixup05-fixup04, fixup06-fixup05, fixup07-fixup06
	.byte	fixup08-fixup07, fixup09-fixup08, fixup10-fixup09
	.byte	fixup11-fixup10, fixup12-fixup11, fixup13-fixup12
	.byte	fixup14-fixup13, fixup15-fixup14, fixup16-fixup15
	.byte	fixup17-fixup16, fixup18-fixup17, fixup19-fixup18
	.byte	fixup20-fixup19, fixup21-fixup20, fixup22-fixup21
	.byte	fixup23-fixup22, fixup24-fixup23

fixups	= * - fixup

;---------------------------------------------------------------------

; The addresses are fixed up at runtime
rxtxreg		:= $C080
txcmd		:= $C084
txlen		:= $C086
isq		:= $C088
packetpp	:= $C08A
ppdata		:= $C08C

;---------------------------------------------------------------------

	.data

init:
	; Convert slot number to slot I/O offset
	asl
	asl
	asl
	asl
	sta reg

	; Start with first fixup location
	lda #<(fixup01+1)
	ldx #>(fixup01+1)
	sta ptr
	stx ptr+1
	ldx #$FF
	ldy #$00

	; Fixup address at location
:	lda (ptr),y
	and #%10001111		; Allow for re-init
	ora reg
	sta (ptr),y

	; Advance to next fixup location
	inx
	cpx #fixups
	bcs :+
	lda ptr
	clc
	adc fixup,x
	sta ptr
	bcc :-
	inc ptr+1
	bcs :-			; Always

	; Check EISA registration number of Crystal Semiconductor
	; PACKETPP = $0000, PPDATA == $630E ?
:	lda #$00
	tax
	jsr packetpp_ax
	lda #$63^$0E
fixup01:eor ppdata
fixup02:eor ppdata+1
	beq reset
	sec
	rts

	.endif

;=====================================================================

	.ifdef __ATARI__

rxtxreg		:= $D500
txcmd		:= $D504
txlen		:= $D506
isq		:= $D508
packetpp	:= $D50A
ppdata		:= $D50C

;---------------------------------------------------------------------

	.code

init:
	; Check EISA registration number of Crystal Semiconductor
	; PACKETPP = $0000, PPDATA == $630E ?
	lda #$00
	tax
	jsr packetpp_ax
	lda #$63^$0E
	eor ppdata
	eor ppdata+1
	beq reset
	sec
	rts

	.endif

;=====================================================================

reset:
	; Initiate a chip-wide reset
	; PACKETPP = $0114, PPDATA = $0040
	lda #$14
	jsr packetpp_a1
	ldy #$40
fixup03:sty ppdata
:	jsr packetpp_a1
fixup04:ldy ppdata
	and #$40
	bne :-

	; Accept valid unicast + broadcast frames
	; PACKETPP = $0104, PPDATA = $0D05
	lda #$04
	jsr packetpp_a1
	lda #$05
	ldx #$0D
	jsr ppdata_ax

	; Set MAC address
	; PACKETPP = $0158, PPDATA = MAC[0], MAC[1]
	; PACKETPP = $015A, PPDATA = MAC[2], MAC[3]
	; PACKETPP = $015C, PPDATA = MAC[4], MAC[5]
	ldy #$58
:	tya
	jsr packetpp_a1
	lda mac-$58,y
	ldx mac-$58+1,y
	jsr ppdata_ax
	iny
	iny
	cpy #$58+6
	bcc :-

	; Turn on transmission and reception of frames
	; PACKETPP = $0112, PPDATA = $00D3
	lda #$12
	jsr packetpp_a1
	lda #$D3
	ldx #$00
	jsr ppdata_ax
	txa
	clc
	rts

;---------------------------------------------------------------------

poll:
	; Check receiver event register to see if there
	; are any valid unicast frames avaliable
	; PACKETPP = $0124, PPDATA & $0D00 ?
	lda #$24
	jsr packetpp_a1
fixup05:lda ppdata+1
	and #$0D
	beq :+

	; Process the incoming frame
	; --------------------------
	
	; Read receiver event and discard it
	; RXTXREG
fixup06:ldx rxtxreg+1
fixup07:lda rxtxreg

	; Read frame length
	; cnt = len = RXTXREG
fixup08:ldx rxtxreg+1
fixup09:lda rxtxreg
	sta len
	stx len+1
	sta cnt
	stx cnt+1

	; Adjust odd frame length
	jsr adjustcnt

	; Is bufsize < cnt ?
	lda bufsize
	cmp cnt
	lda bufsize+1
	sbc cnt+1
	bcs :++

	; Yes, skip frame
	jsr skipframe

	; No frame ready
	lda #$00
:	tax
	sec
	rts

	; Read bytes into buffer
:	jsr adjustptr
:
fixup10:lda rxtxreg
	sta (ptr),y
	iny
fixup11:lda rxtxreg+1
	sta (ptr),y
	iny
	bne :-
	inc ptr+1
	dex
	bpl :-

	; Return frame length
	lda len
	ldx len+1
	clc
	rts

;---------------------------------------------------------------------

send:
	; Save frame length
	sta cnt
	stx cnt+1

	; Transmit command
	lda #$C9
	ldx #$00
fixup12:sta txcmd
fixup13:stx txcmd+1
	lda cnt
	ldx cnt+1
fixup14:sta txlen
fixup15:stx txlen+1

	; Adjust odd frame length
	jsr adjustcnt

	; 8 retries
	ldy #$08

	; Check for avaliable buffer space
	; PACKETPP = $0138, PPDATA & $0100 ?
:	lda #$38
	jsr packetpp_a1
fixup16:lda ppdata+1
	and #$01
	bne :+

	; No space avaliable, skip a received frame
	jsr skipframe

	; And try again
	dey
	bne :-
	sec
	rts

	; Send the frame
	; --------------

	; Write bytes from buffer
:	jsr adjustptr
:	lda (ptr),y
fixup17:sta rxtxreg
	iny
	lda (ptr),y
fixup18:sta rxtxreg+1
	iny
	bne :-
	inc ptr+1
	dex
	bpl :-
	clc
	rts

;---------------------------------------------------------------------

exit:
	rts

;---------------------------------------------------------------------

packetpp_a1:
	ldx #$01
packetpp_ax:
fixup19:sta packetpp
fixup20:stx packetpp+1
	rts

;---------------------------------------------------------------------

ppdata_ax:
fixup21:sta ppdata
fixup22:stx ppdata+1
	rts

;---------------------------------------------------------------------

skipframe:
	; PACKETPP = $0102, PPDATA = PPDATA | $0040
	lda #$02
	jsr packetpp_a1
fixup23:lda ppdata
	ora #$40
fixup24:sta ppdata
	rts

;---------------------------------------------------------------------

adjustcnt:
	lsr
	bcc :+
	inc cnt
	bne :+
	inc cnt+1
:	rts

;---------------------------------------------------------------------

adjustptr:
	lda cnt
	ldx cnt+1
	eor #$FF		; Two's complement part 1
	tay
	iny			; Two's complement part 2
	sty reg
	sec
	lda bufaddr
	sbc reg
	sta ptr
	lda bufaddr+1
	sbc #$00
	sta ptr+1
	rts

;---------------------------------------------------------------------
