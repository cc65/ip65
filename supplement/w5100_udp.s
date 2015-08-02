.feature c_comments

/******************************************************************************

Copyright (c) 2014, Oliver Schmidt
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL OLIVER SCHMIDT BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

******************************************************************************/

.export _w5100_init
.export _w5100_recv_init, _w5100_recv_byte, _w5100_recv_done
.export _w5100_send_init, _w5100_send_byte, _w5100_send_done

ptr  := $06         ; 2 byte pointer value
sha  := $08         ; 2 byte physical addr shadow ($F000-$FFFF)
adv  := $EB         ; 2 byte pointer register advancement
len  := $ED         ; 2 byte frame length
tmp  := $FA         ; 1 byte temporary value
bas  := $FB         ; 1 byte socket 1 Base Address (hibyte)

mode := $C0B4
addr := $C0B5
data := $C0B7

;------------------------------------------------------------------------------

_w5100_init:
; Input
;       AX: Address of ip_parms (serverip, cfg_ip, cfg_netmask, cfg_gateway)
; Output
;       None
; Remark
;       The ip_parms are only accessed during this function.

        ; Set ip_parms pointer
        sta ptr
        stx ptr+1

        ; S/W Reset
        lda #$80
        sta mode
:       lda mode
        bmi :-

        ; Indirect Bus I/F mode, Address Auto-Increment
        lda #$03
        sta mode

        ; Gateway IP Address Register: IP address of router on local network
        ldx #$00                ; Hibyte
        ldy #$01                ; Lobyte
        jsr set_addr
        ldy #3*4                ; ip_parms::cfg_gateway
        jsr set_ipv4value

        ; Subnet Mask Register: Netmask of local network
        ; -> addr is already set
        ldy #2*4                ; ip_parms::cfg_netmask
        jsr set_ipv4value

        ; Source Hardware Address Register: MAC Address
        ; -> addr is already set
        ldx #$00
:       lda mac,x
        sta data
        inx
        cpx #$06
        bcc :-

        ; Source IP Address Register: IP address of local machine
        ; -> addr is already set
        ldy #1*4                ; ip_parms::cfg_ip
        jsr set_ipv4value

        ; RX Memory Size Register: Assign 4KB each to sockets 0 and 1
        ldx #$00                ; Hibyte
        ldy #$1A                ; Lobyte
        jsr set_addr
        lda #$0A
        sta data

        ; TX Memory Size Register: Assign 4KB each to sockets 0 and 1
        ; -> addr is already set
        ; -> A is still $0A
        sta data

        ; Socket 1 Source Port Register: 6502
        ldy #$04
        jsr set_addrsocket1
        jsr set_data6502

        ; Socket 1 Destination IP Address Register: Destination IP address
        ; This has to be the last call to set_ipv4value because it writes
        ; as a side effect to 'hdr' and it is the destination IP address
        ; that has to be present in 'hdr' after initialization
        ldy #$0C
        jsr set_addrsocket1
        ldy #0*4                ; ip_parms::serverip
        jsr set_ipv4value

        ; Socket 1 Destination Port Register: 6502
        ; -> addr is already set
        jsr set_data6502

        ; Socket 1 Mode Register: UDP
        ldy #$00
        jsr set_addrsocket1
        lda #$02
        sta data

        ; Socket 1 Command Register: OPEN
        ; -> addr is already set
        lda #$01
        sta data
        rts

;------------------------------------------------------------------------------

set_ipv4value:
        ldx #$03
:       lda (ptr),y
        iny
        sta data
        sta hdr+2,x
        dex
        bpl :-
        rts

;------------------------------------------------------------------------------

set_data6502:
        lda #<6502
        ldx #>6502
        stx data                ; Hibyte
        sta data                ; Lobyte
        rts

;------------------------------------------------------------------------------

_w5100_recv_init:
; Input
;       None
; Output
;       AX: Number of bytes to receive
; Remark
;       To be called before recv_byte.

        ; Socket 1 RX Received Size Register: 0 or volatile ?
        lda #$26                ; Socket RX Received Size Register
        jsr prolog
        bne error

        ; Socket 1 RX Read Pointer Register
        ; -> addr already set

        ; Calculate and set pyhsical address
        ldx #>$7000             ; Socket 1 RX Base Address
        jsr set_addrphysical

        ; Compare peer IP addr and peer port with expected values
        ; in 'hdr' and set C(arry flag) if there's a mismatch
        clc
        ldx #$05
        stx tmp
:       jsr _w5100_recv_byte    ; Doesn't trash C
        ldx tmp
        eor hdr,x               ; Doesn't trash C
        beq :+
        sec
:       dec tmp
        bpl :--
        php                     ; Save C

        ; Read data length
        jsr _w5100_recv_byte    ; Hibyte
        sta len+1
        jsr _w5100_recv_byte    ; Lobyte
        sta len

        ; Add 8 byte header to set pointer advancement
        clc
        adc #<$0008
        sta adv
        lda len+1
        adc #>$0008
        sta adv+1

        ; Skip frame if it doesn't originate from our
        ; expected communicaion peer
        plp                     ; Restore C
        bcs _w5100_recv_done

        ; Return data length
        lda len
        ldx len+1
        rts

;------------------------------------------------------------------------------

_w5100_send_init:
; Input
;       AX: Number of bytes to send
; Output
;       A: Nonzero if ready to send
; Remark
;       To be called before send_byte.

        ; Set pointer advancement
        sta adv
        stx adv+1

        ; Socket 1 TX Free Size Register: 0 or volatile ?
        lda #$20                ; Socket TX Free Size Register
        jsr prolog
        bne error

        ; Socket 1 TX Free Size Register: < advancement ?
        cpx adv                 ; Lobyte
        sbc adv+1               ; Hibyte
        bcc error               ; Not enough free size

        ; Socket 1 TX Write Pointer Register
        ldy #$24
        jsr set_addrsocket1

        ; Calculate and set pyhsical address
        ldx #>$5000             ; Socket 1 TX Base Address
        jsr set_addrphysical

        ; Return success
        lda #$01
        ldx #>$0000             ; Required by cc65 C callers
        rts

;------------------------------------------------------------------------------

error:
        lda #<$0000
        tax
        rts

;------------------------------------------------------------------------------

prolog:
        ; Check for completion of previous command
        ; Socket 1 Command Register: 0 ?
        jsr set_addrcmdreg1
        ldx data
        bne :++                 ; Not completed -> Z = 0

        ; Socket Size Register: not 0 ?
        tay                     ; Select Size Register
        jsr get_wordsocket1
        stx ptr                 ; Lobyte
        sta ptr+1               ; Hibyte
        ora ptr
        bne :+
        inx                     ; -> Z = 0
        rts

        ; Socket Size Register: volatile ?
:       jsr get_wordsocket1
        cpx ptr                 ; Lobyte
        bne :+                  ; Volatile size -> Z = 0
        cmp ptr+1               ; Hibyte
        ; bne :+                ; Volatile size -> Z = 0
:       rts

;------------------------------------------------------------------------------

_w5100_recv_byte:
; Input
;       None
; Output
;       A: Byte received
; Remark
;       May be called as often as indicated by recv_init.

        ; Read byte
        lda data

        ; Increment physical addr shadow lobyte
        inc sha
        beq incsha
        ldx #>$0000             ; Required by cc65 C callers
        rts

;------------------------------------------------------------------------------

_w5100_send_byte:
; Input
;       A: Byte to send
; Output
;       None
; Remark
;       Should be called as often as indicated to send_init.

        ; Write byte
        sta data

        ; Increment physical addr shadow lobyte
        inc sha
        beq incsha
        rts

incsha:
        ; Increment physical addr shadow hibyte
        inc sha+1
        beq set_addrbase
        ldx #>$0000             ; Required by cc65 C callers (_w5100_recv_byte)
        rts

;------------------------------------------------------------------------------

_w5100_recv_done:
; Input
;       None
; Output
;       None
; Remark
;       Mark data indicated by recv_init as processed (independently from how
;       often recv_byte was called), if not called then next call of recv_init
;       will just indicate the very same data again.

        ; Set parameters for commit code
        lda #$40                ; RECV
        ldy #$28                ; Socket RX Read Pointer Register
        bne epilog              ; Always

;------------------------------------------------------------------------------

_w5100_send_done:
; Input
;       None
; Output
;       None
; Remark
;       Actually send data indicated to send_init (independently from how often
;       send_byte was called), if not called then send_init (and send_byte) are
;       just NOPs.

        ; Set parameters for commit code
        lda #$20                ; SEND
        ldy #$24                ; Socket TX Write Pointer Register

epilog:
        ; Advance pointer register
        jsr set_addrsocket1
        tay                     ; Save command
        clc
        lda ptr
        adc adv
        tax
        lda ptr+1
        adc adv+1
        sta data                ; Hibyte
        stx data                ; Lobyte

        ; Set command register
        tya                     ; Restore command
        jsr set_addrcmdreg1
        sta data

        ; Return error (_w5100_recv_init)
        bne error               ; Always

;------------------------------------------------------------------------------

set_addrphysical:
        lda data                ; Hibyte
        ldy data                ; Lobyte
        sty ptr
        sta ptr+1
        and #>$0FFF             ; Socket Mask Address (hibyte)
        stx bas                 ; Socket Base Address (hibyte)
        ora bas
        tax
        ora #>$F000             ; Move sha/sha+1 to $F000-$FFFF
        sty sha
        sta sha+1

set_addr:
        stx addr                ; Hibyte
        sty addr+1              ; Lobyte
        ldx #>$0000             ; Required by cc65 C callers (_w5100_recv_byte)
        rts

;------------------------------------------------------------------------------

set_addrcmdreg1:
        ldy #$01                ; Socket Command Register

set_addrsocket1:
        ldx #>$0500             ; Socket 1 register base address
        bne set_addr            ; Always

;------------------------------------------------------------------------------

set_addrbase:
        ldx bas                 ; Socket Base Address (hibyte)
        ldy #<$0000             ; Socket Base Address (lobyte)
        beq set_addr            ; Always

;------------------------------------------------------------------------------

get_wordsocket1:
        jsr set_addrsocket1
        lda data                ; Hibyte
        ldx data                ; Lobyte
        rts

;------------------------------------------------------------------------------

.rodata

mac:    .byte $00, $08, $DC     ; OUI of WIZnet
        .byte $11, $11, $11

;------------------------------------------------------------------------------

.data

hdr:    .word 6502              ; Destination Port
        .res  4                 ; Destination IP Address
