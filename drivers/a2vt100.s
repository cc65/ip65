.feature labels_without_colons
.feature leading_dot_in_identifiers
.feature loose_char_term
.define .asc .byt

.export vt100_init_terminal         = InitTerminal
.export vt100_exit_terminal         = ExitTerminal
.export vt100_process_inbound_char  = ProcIn
.export vt100_process_outbound_char = ProcOut
.exportzp vt100_screen_cols         = 80
.exportzp vt100_screen_rows         = 24

.import beep
.import telnet_close
.import telnet_send_char
.import telnet_send_string

putRS   = telnet_send_char
SendStr = telnet_send_string

; *************************************
; *                                   *
; *             C a T e r             *
; *                                   *
; *           Copyright by            *
; *         Lars Stollenwerk          *
; *                                   *
; *           2001 - 2003             *
; *                                   *
; * This file is part of CaTer.       *
; *                                   *
; * CaTer is provided under the terms *
; * of GNU General Public License.    *
; *                                   *
; * For more information see the      *
; * README file.                      *
; *                                   *
; *************************************

; *************************************
; *
; * Constant declaration
; *
; *************************************

.include "apple2.inc"

ControlFlags = $1000

; *************************************
; *
; * Zeropage
; *
; *************************************

.include "zeropage.inc"

; --- Vector ---
; four vectors in zeropage for
; temporary use.
zVector = ptr1
xVector = ptr2

; --- vector for PrnScr ---
vVector = ptr3

; *************************************
; *
; * Variables
; *
; *************************************

.bss

; --- esc mode ---
; $00 = normal
; $0f = esc mode
; $ff = esc [ mode
; $f0 = ignore one char
EMode .res 1

; --- esc buffer ---
EBuf .res $100

; --- esc buffer length ---
; points on first free position
EBufL .res 1

; --- esc parameter ---
; numeric parameter in esc sequence
EPar .res 1

; --- scroll region ---
SRS .res 1     ; first line number
SRE .res 1     ; last line number

; --- ANSI font attributes ---
; contains three bits
; bit 0 = reverse
; bit 1 = bold
; bit 2 = underline
Font: .res 1

; --- crsr save area ---
; here is crsr info saved with ESC 7
; and restored from with ESC 8
SaveF .res 1   ; font
SaveR .res 1   ; reverse mode
SaveRow .res 1 ; row
SaveCol .res 1 ; column

; --- Linebreak pending ---
; 0 = not pending, ff = pending
lbPending .res 1

; --- crsr invisible ---
; 0 = visible, !0 = invisible
civis .res 1

; --- char under crsr ---
sCrsrChar .res 1

; --- buffer for addDecDig ---
mul10buf .res 1

; *************************************
; *
; * Code
; *
; *************************************

.code

; -------------------------------------
; init terminal
;
; -------------------------------------

InitTerminal
        jsr InitVar ; memory variables
        jsr InitChar; init font
        jsr InitScr ; init screen
        rts

; -------------------------------------
; exit terminal
;
; -------------------------------------

ExitTerminal
        jsr ExitChar; exit font
        jsr ExitScr ; exit screen
        rts

; *************************************
; *
; * imcoming data
; *
; *************************************

; -------------------------------------
; process incoming data
;
; char in Y
; -------------------------------------

ProcIn  lda EMode   ; handle esc mode
        bne PIEsc
        cpy #$20    ; control?
        bcc Special
        tya
        jsr CPrnChr ; print to screen
        rts

; to far for branch
PIEsc   jmp Esc

; -------------------------------------
; special incoming char
;
; -------------------------------------

Special tya         ; restore char
; --- CR ---
        cmp #$0d    ; CR?
        bne D1
CR      jsr clPending
        ldx CV      ; get row
        ldy #$00    ; set col=0
        jsr CPlot   ; set crsr
        rts
; --- BS ---
D1      cmp #$08    ; BS?
        bne D2
BS      jsr clPending
        ldy CH      ; get col
        beq D1rts   ; stop @ left margin
        dey         ; dec column
        ldx CV      ; get row
        jsr CPlot   ; set crsr
D1rts   rts
; --- ESC ---
D2      cmp #$1b    ; esc?
        bne D3
        lda #$0f    ; set esc mode
        sta EMode
        rts
; --- BEL ---
D3      cmp #$07    ; BEL?
        bne D4
        jsr beep
        rts
; --- LF ---
D4      cmp #$0a    ; LF?
        bne D5
LF      jsr clPending
        ldx CV      ; crsr line
        cpx SRE     ; end scroll region?
        bne D4a     ;  no -> branch
        jsr CUScrl  ;  yes -> scroll up
        rts
D4a     cpx #$17    ; end of screen?
        bne D4b     ;  no -> branch
        rts         ;  yes -> do nothing
D4b     inx         ; next line
        ldy CH      ; get col
        jsr CPlot   ; set crsr
        rts
; --- TAB ---
D5      cmp #$09    ; TAB?
        bne D6
        ; don't clear pending
        ; don't set pending
        lda CH      ; crsr col
        and #$f8    ; (col DIV 8) * 8
        clc         ; col + 8
        adc #$08
        cmp #$50    ; col=80?
        bne D5a     ; no -> skip
        lda #$4f    ; yes -> col=79
D5a     tay         ; col to y
        ldx CV      ; line to x
        jsr CPlot   ; set crsr
        rts

D6      rts

; -------------------------------------
; esc mode
;
; char in Y
; EMode != $00 in A
; -------------------------------------

Esc     tax         ; save EMode
        and #$0f    ; EMode = $0f?
        bne E1

; --- throw mode --- EMode = $f0
;     throw away char
        lda #$00    ; reset EMode
        sta EMode
        rts

E1      txa         ; restore EMode
        and #$f0    ; EMode = $ff?
        beq SEsc    ; no -> short Emode
        jmp LEsc    ; yes -> long Emode

; -------------------------------------
; short esc mode
;
; EMode = $0f
; process first char
; -------------------------------------

SEsc    tya         ; restore char
        ; --- [ ---
        cmp #$5b  ; [ ?
        bne E2
        lda #$ff    ; set esc [ mode
        sta EMode
        rts
        ; --- ( ---
E2      cmp #$28    ; ( ?
        bne E3
        jmp sThrow
        ; --- ) ---
E3      cmp #$29    ; ) ?
        bne E4
        jmp sThrow
        ; --- # ---
E4      cmp #$23    ; # ?
        bne E5
        jmp sThrow
        ; --- D --- index
E5      cmp #$44    ; D ?
        bne E6
        jsr LF      ; same as LF
        jmp Eend
        ; --- M --- reverse index
E6      cmp #$4d    ; M ?
        bne E7
        jsr clPending
        ldx CV      ; get crsr row
        cpx SRS     ; top os scroll reg?
        bne E6a
        jsr CDScrl  ; yes -> scroll down
        jmp Eend
E6a     cpx #$00    ; top of screen?
        bne E6b
        jmp Eend    ; yes -> do nothing
E6b     dex         ; one line up
        ldy CH      ; get crsr col
        jsr CPlot   ; set crsr
        jmp Eend
        ; --- E --- next line
E7      cmp #$45    ; E ?
        bne E8
        jsr CR
        jsr LF
        jmp Eend
        ; --- 7 --- save crsr
E8      cmp #$37    ; 7 ?
        bne E9
        lda Font    ; save font
        sta SaveF
        lda INVFLG  ; save reverse mode
        sta SaveR
        ldx CV      ; save position
        ldy CH
        stx SaveRow
        sty SaveCol
        jmp Eend
        ; --- 8 --- restore crsr
E9      cmp #$38    ; 8 ?
        bne E10
        jsr clPending
        ldx SaveRow ; restore pos
        ldy SaveCol
        jsr CPlot
        lda SaveR   ; restore ..
        sta INVFLG  ; .. reverse mode
        ldx SaveF   ; restore font
        stx Font
        jmp Eend

        ; --- unknown ---
E10

        ; --- reset ESC mode ---
Eend    lda #$00    ; reset EMode
        sta EMode
        rts

        ; --- set Throw mode ---
sThrow  lda #$f0    ; set esc mode $f0
        sta EMode
        rts

; -------------------------------------
; [ esc mode
;
; EMode = $ff
; -------------------------------------

LEsc    tya         ; restore char

        ldy EBufL
        sta EBuf,y  ; store char
        iny
        sty EBufL   ; inc esc buffer

        jsr TestL   ; test letter
        bcs LE1     ; process command
        rts

; --- process esc command ---
; A = last char
; Y = EBufL
; X conunts processed command chars
LE1     ldx #$00    ; first char

; --- A --- crsr up
        cmp #$41    ; A ?
        bne LE2
        jsr clPending
        jsr GetNum  ; get argument
        lda EPar    ; EPar = 0...
        bne LE1c
        inc EPar    ; .. means 1
LE1c    lda CV      ; get crsr row
        sec
        sbc EPar    ; row = row - up
        cmp SRS     ; stop at top of ..
        bpl LE1a    ; ..scroll region
        lda SRS
LE1a    tax         ; x is row
        ldy CH      ; y is col
        jsr CPlot   ; set crsr
        jmp LEend

; --- B --- crsr down
LE2     cmp #$42    ; B ?
        bne LE3
        jsr clPending
        jsr GetNum  ; get argument
        lda EPar    ; EPar = 0...
        bne LE2c
        inc EPar    ; .. means 1
LE2c    lda CV      ; get crsr row
        clc
        adc EPar    ; row = row + down
        cmp SRE     ; outside scrregion?
        bcs LE2d    ; yes -> branch
        tax         ; x is row
        jmp LE2a
LE2d    ldx SRE     ; x = row = SRE
LE2a    ldy CH      ; y is col
        jsr CPlot   ; set crsr
        jmp LEend

; --- C --- crsr right
LE3     cmp #$43    ; C ?
        bne LE4
        jsr clPending
        jsr GetNum  ; get argument
        lda EPar    ; EPar = 0...
        bne LE3c
        inc EPar    ; .. means 1
LE3c    lda CH      ; get crsr col
        clc
        adc EPar    ; col = col + right
        cmp #$4f    ; outside screen?
        bcs LE3d    ; yes -> branch
        tay
        jmp LE3a
LE3d    ldy #$4f    ; y=col=left margin
LE3a    ldx CV      ; x is row
        jsr CPlot   ; set crsr
        jmp LEend

; --- D --- crsr left
LE4     cmp #$44    ; D ?
        bne LE5
        jsr clPending
        jsr GetNum  ; get argument
        lda EPar    ; EPar = 0...
        bne LE4c
        inc EPar    ; .. means 1
LE4c    lda CH      ; get crsr col
        sec
        sbc EPar    ; col = col - left
        bpl LE4a    ; stop at left..
        lda #$00    ; ..margin
LE4a    tay         ; y is col
        ldx CV      ; x is row
        jsr CPlot   ; set crsr
        jmp LEend

; --- m ---  font attributes
LE5     cmp #$6d    ; m ?
        beq LE5a
        jmp LE6     ; too far to branch
LE5a    jsr GetNum
        pha         ; save nondigit char
        lda Font    ; font to A
        ldy EPar    ; parameter to Y
        ; -- 0 --
        bne LE5b    ; 0 ?
        tya         ; set font = vanilla
        jmp LE5nx
        ; -- 1 -- bold
LE5b    cpy #$01
        bne LE5c
        ora #$02    ; bit 1 = bold
        jmp LE5nx
        ; -- 4 -- underline
LE5c    cpy #$04
        bne LE5d
        ora #$04    ; bit 2 = underline
        jmp LE5nx
        ; -- 7 -- reverse
LE5d    cpy #$07
        bne LE5nx
        ora #$01    ; bit 0 = reverse
LE5nx   ; -- next char --
        sta Font
        pla         ; get nondigit char
        cmp #$3b    ; is semicolon?
        beq LE5a    ; then next param
        ; set ANSI font attributes
        lda Font
        ldx #$ff    ; reverse off
        lsr         ; reverse?
        bcc LE5k
        ldx #$3f    ; reverse on
LE5k    stx INVFLG  ; set reverse mode
        jmp LEend

; --- K --- erase line
LE6     cmp #$4b      ; K ?
        bne LE7
        jsr GetNum    ; get parameter
        lda EPar      ; in A
        ; -- 0 -- crsr to end of line
        bne LE6b
        jsr ErEnLn    ; erase end line
        jmp LEend
        ; -- 1 -- begin to crsr
LE6b    cmp #$01
        bne LE6d
        jsr ErBeLn    ; erase beg line
        jmp LEend
        ; -- 2 -- whole line
LE6d    cmp #$02
        bne LE6e      ; par undefined
        ldx CV        ; line in X
        jsr ErLn      ; erase line
        sta sCrsrChar ; del char ..
                      ; ..under crsr
LE6e    jmp LEend


; --- f --- same as H
LE7     cmp #$66
        bne LE8
        jmp LE7a      ; same as H

; --- H --- cursor position
LE8     cmp #$48
        bne LE9
LE7a    jsr clPending
        cpy #$01    ; no par means home
        bne LE8a
        ; -- home --
        ldx #$00
        ldy #$00
        jsr CPlot   ; set crsr
        jmp LEend
        ; -- row, col --
LE8a    jsr GetNum
        cmp #$3b    ; is ;?
        bne LE8d    ; no -> error
        ; -- prepare row --
        ldy EPar    ; get row
        bne LE8b    ; 0 means 1
        iny
LE8b    dey         ; line 1 -> line 0
        cpy #$18    ; >= 24?..
        bcs LE8d    ; ..error!
        sty xVector ; save row
        ; -- prepare col
        jsr GetNum
        ldy EPar    ; get col
        bne LE8c    ; 0 means 1
        iny
LE8c    dey         ; col 1 -> col 0
        cpy #$50    ; >= 80?..
        bcs LE8d    ; ..error!
        ldx xVector ; restore row to X
        jsr CPlot   ; set crsr
LE8d    jmp LEend

; --- J --- erase screen
LE9     cmp #$4a      ; J ?
        bne LE10
        jsr GetNum    ; get parameter
        lda EPar      ; in A
        ; -- 0 -- crsr to end
        bne LE9a
        jsr ErEnLn    ; del rest of line
        ldx CV        ; get crsr line
LE9b    inx           ; next line
        cpx #$18      ; line 24?
        bcs LE9f      ; then end
        txa
        pha           ; save X
        jsr ErLn      ; erase line
        pla
        tax           ; restore X
        jmp LE9b      ; next line
        ; -- 1 -- beg of screen to crsr
LE9a    cmp #$01
        bne LE9e
        jsr ErBeLn    ; del start of ln
        ldx CV        ; get crsr line
LE9c    dex           ; previous line
        bmi LE9f      ; neg line -> end
        txa
        pha           ; save X
        jsr ErLn      ; erase line
        pla
        tax           ; restore X
        jmp LE9c
        ; -- 2 -- del screen
LE9e    cmp #$02      ; unknown?
        bne LE9f      ; then ingnore
        ldx #$17      ; start at ln 23
LE9d    txa
        pha           ; save X
        jsr ErLn      ; erase line
        pla
        tax           ; restore X
        dex           ; previous line
        bpl LE9d
LE9f    jmp LEend

; --- r ---  set scroll region
LE10    cmp #$72    ; r ?
        bne LE11
        ; -- prepare top --
        jsr GetNum
        cmp #$3b    ; is ;?
        bne LE10e   ; no -> error
        ldy EPar    ; get top
        dey         ; line 1 -> line 0
        cpy #$18    ; >=24?..
        bcs LE10e   ; ..error!
        sty xVector ; save top
        ; -- prepare bottom --
        jsr GetNum
        ldy EPar    ; get bottom
        dey         ; line 1 -> line 0
        cpy #$18    ; >=24?..
        bcs LE10e   ; ..error!
        sty zVector ; save bottom
        ; -- validate lines --
        lda xVector ; restore top
        cmp zVector ; >= bottom?..
        bcs LE10e   ; ..error!
        sta SRS     ; top -> SRStart
        sty SRE     ; bottom -> SREnd
        ; -- home crsr
        jsr clPending
        ldx #$00
        ldy #$00
        jsr CPlot
LE10e   jmp LEend

; --- l --- set crsr invisible
LE11    cmp #$6c    ; l ?
        bne LE12
        lda EBuf    ; first char ..
        cmp #$3f    ; .. is '?' ?
        bne LE11a
        inx         ; at second char ..
        jsr GetNum
        lda EPar
        cmp #25     ; .. 25 ?
        bne LE11a
        jsr COff    ; switch crsr off
        sta civis   ; mark invisible
LE11a   jmp LEend

; --- h --- set crsr visible
LE12    cmp #$68    ; h ?
        bne LE13
        lda EBuf    ; first char ..
        cmp #$3f    ; ... is '?' ?
        bne LE12a
        inx         ; at second char ..
        jsr GetNum
        lda EPar
        cmp #25     ; .. 25 ?
        bne LE12a
        lda #$00
        sta civis   ; mark visible
        jsr COn     ; switch crsr off
LE12a   jmp LEend

LE13
; --- unknown esc seqence ---
LEend   lda #$00
        sta EBufL   ; reset esc buffer
        sta EMode   ; reset esc mode
        rts

; -------------------------------------
; GetNum - get decimal number from
;          esc sequence
;
; params: esc sequence in EBuf
;         first index to process in X
; affects: A, X, Y
; return: number in EPar
;         first non digit char in  A
;         next index to process in X
; -------------------------------------

GetNum  lda #$00    ; init value
        sta EPar
GN2     lda EBuf,x  ; get next char
        inx
        jsr TestD   ; digit?
        bcc GN1     ; no -> return
        tay         ; digit to Y
        lda EPar
        jsr addDecDig
        sta EPar
        jmp GN2     ; next char

GN1     rts

; -------------------------------------
; TestL - Test letter
;
; params: char in A
; affects: none
; return: c = 1 for letter
;         c = 0 for no letter
; -------------------------------------

TestL   cmp #$41    ; smaller then A?
        bcs TL1     ; no -> go on
        rts         ; return no letter

TL1     cmp #$5b    ; smaller then Z+1?
        bcs TL2     ; no -> go on
        sec         ; return letter
        rts

TL2     cmp #$61    ; smaller then a?
        bcs TL3     ; no -> go on
        rts         ; return no letter

TL3     cmp #$7b    ; smaller then z+1?
        bcs TL4     ; no -> go on
        sec         ; return letter
        rts

TL4     clc         ; return no letter
        rts

; -------------------------------------
; TestD - test digit
;
; params: char in A
; affects: none
; return: c = 1 for digit
;         c = 0 for no digit
; -------------------------------------

TestD   cmp #$30    ; smaller then 0?
        bcs TD1     ; no -> go on
        rts         ; return no digit

TD1     cmp #$3a    ; smaller then 9+1?
        bcs TD2     ; no -> go on
        sec         ; return digit
        rts

TD2     clc         ; return no digit
        rts

; -------------------------------------
; addDecDig - add decimal digit
;
; multiply A * 10, add Y
;
; param: present number in A
;        new digit in Y (may be ASCII digit)
; affects: A
; return: 10 times the number in A + Y
;         c = 1 overflow occured,
;               number invalid
;         c = 0 no overflow
; -------------------------------------

addDecDig
        ; --- inc value ---
        ; old value * 10
        ; 10a = ( 4a + a ) * 2
        sta mul10buf
        clc
        asl           ; ( 4a
        bcs aDDigE
        asl
        bcs aDDigE
        adc mul10buf  ; + a )
        bcs aDDigE
        asl           ; *2
        bcs aDDigE
        sta mul10buf
        ; --- add Y ---
        tya
        and #$0f      ; digit to val
        adc mul10buf

aDDigE  rts

; *************************************
; *
; * outgoing data
; *
; *************************************

; -------------------------------------
; process outgoing key
;
; params: key in Y
; -------------------------------------

ProcOut
        lda kta,y   ; keyboard to ASCII
        beq POrts   ; ignore key
        cmp #$fe
        beq CmdKey  ; command key
        jsr putRS
POrts   rts

; -------------------------------------
; outgoing command key
;
; -------------------------------------

ScrsrU .byt $1b, $4f, $41, $00 ; esc O A
ScrsrD .byt $1b, $4f, $42, $00 ; esc O B
ScrsrR .byt $1b, $4f, $43, $00 ; esc O C
ScrsrL .byt $1b, $4f, $44, $00 ; esc O D

CmdKey  tya         ; restore character

; --- crsr L ---
; ---   ^H   ---
; both events send char $08
        cmp #$08
        bne C0
        bit BUTN0   ; Open-Apple key
        bpl crsrL   ; not pressed
        jsr putRS   ; send ^H
        rts

        ; crsr L
crsrL   ldx #<ScrsrL
        ldy #>ScrsrL
        jsr SendStr
        rts

; --- crsr D ---
; ---   ^J   ---
; both events send char $0a
C0      cmp #$0a
        bne C1
        bit BUTN0   ; Open-Apple key
        bpl crsrD   ; not pressed
        jsr putRS   ; send ^J
        rts

        ; crsr down is pressed
crsrD   ldx #<ScrsrD
        ldy #>ScrsrD
        jsr SendStr
        rts

; --- crsr U ---
; ---   ^K   ---
; both events send char $0b
C1      cmp #$0b
        bne C2
        bit BUTN0   ; Open-Apple key
        bpl crsrU   ; not pressed
        jsr putRS   ; send ^K
        rts

        ; crsr up is pressed
crsrU   ldx #<ScrsrU
        ldy #>ScrsrU
        jsr SendStr
        rts

; --- crsr R ---
; ---   ^U   ---
; both events send char $15
C2      cmp #$15
        bne C3
        bit BUTN0   ; Open-Apple key
        bpl crsrR   ; not pressed
        jsr putRS   ; send ^U
        rts

        ; crsr R
crsrR   ldx #<ScrsrR
        ldy #>ScrsrR
        jsr SendStr
        rts

; ---  Open-Apple q ---
; quit CaTer
C3      cmp #$71    ; q
        bne C4
        bit BUTN0   ; Open-Apple key
        bmi Cquit   ; pressed
        jsr putRS   ; send q
        rts

        ; quit CaTer
Cquit   jsr telnet_close
        rts

; --- unknown character ---
C4      rts

; *************************************
; *
; * screen handling
; *
; *************************************

; -------------------------------------
; COff - switch cursor off
;
; affects: none
;
; Switch cursor off and restore char.
; This has to be done before every crsr
; movement.
; After movement COn has to be called.
; -------------------------------------

COff    pha            ; save registers
        tya
        pha

        lda civis      ; invisible?
        bne CO2        ; -> do nothing
        lda CH         ; get column
        lsr            ; column DIV 2
        tay
        lda sCrsrChar  ; restore char
        bcs CO1         ; odd column?
        bit $c055
CO1     sta (BASL),y
        bit $c054
CO2     pla         ; restore registers
        tay
        pla
        rts

; -------------------------------------
; COn - switch crsr on
;
; affects: none
;
; opposite of COff
; -------------------------------------

COn     pha
        tya
        pha

        lda civis        ; invisible?
        bne COn4         ; -> do nothing
        lda CH           ; get column
        lsr              ; column DIV 2
        tay
        bcs COn1         ; odd column?
        bit $c055
COn1    lda (BASL),y     ; save chr
        sta sCrsrChar
        and #$20         ; capital letter?
        beq COn2         ; yes
        lda sCrsrChar
        eor #$80         ; reverse char
        jmp COn3
COn2    lda sCrsrChar
        eor #$c0         ; reverse capital letter
COn3    sta (BASL),y
        bit $c054

COn4    pla
        tay
        pla
        rts

; -------------------------------------
; CPlot - move cursor
;
; params: coumn in Y
;         line in X
; affects: A, X, Y
;
; The crsr ist turned off during
; operation (COff - COn)
; -------------------------------------

CPlot   jsr COff
        jsr Plot
        jsr COn
        rts

; -------------------------------------
; Plot - move cursor
;
; params: coumn in Y
;         line in X
; affects: A, X, Y
; -------------------------------------

Plot    stx CV      ; set row
        sty CH      ; set col
        jsr SLV
        ldx xVector ; set screen line
        ldy xVector+1
        stx BASL
        sty BASH
        rts

; -------------------------------------
; CPrnChr - print char to screen
;
; params: chr in A, $ff means no output
; affects: A
; uses: xVector
;
; The crsr ist turned off during
; operation (COff - COn)
; -------------------------------------

CPrnChr jsr COff
        jsr PrnChr
        jsr COn
        rts

; -------------------------------------
; PrnChr - print char to screen
;
; params: chr in A, $80 means no output
; affects: A
; uses: xVector
; -------------------------------------

PrnChr  sta xVector ; save char
        txa         ; save registers
        pha
        tya
        pha
        lda xVector ; restore char

        ; -- $80-$ff -- non-ASCII
        bpl PC1
        jmp PCend
        ; -- $20-$7f -- printable
PC1     cmp #$20
        bcc PC2
        jmp PCrvs
        ; -- $00-$1f -- control
PC2     jmp PCend   ; no output

        ; -- handle reverse mode --
PCrvs   ora #$80    ; turn on high bit
        ldy INVFLG
        cpy #$FF    ; normal character display mode?
        beq PCput
        cmp #$E0    ; lowercase?
        bcc mask
        and #$7F    ; inverse lowercase
        jmp PCput
mask    and INVFLG  ; apply normal, inverse, flash

PCput   ldx lbPending   ; need new line?
        beq PC6         ; no -> skip
        ldx #$00        ; clear pending
        stx lbPending
        jsr NewLn
PC6     tax             ; save char
        lda CH          ; get crsr col
        lsr             ; col DIV 2
        tay
        txa             ; restore char
        bcs PC7         ; odd col?
        bit $c055
PC7     sta (BASL),y    ; char to screen
        bit $c054
        ldy CH          ; get crsr col

        ; -- move on crsr --
        cpy #$4f        ; col = 79?
        bne PC8         ; no -> skip
        lda #$ff        ; yes -> set..
        sta lbPending   ; ..pending
        jmp PCend
PC8     iny             ; move on crsr
        sty CH

PCend   pla         ; restore registers
        tay
        pla
        tax
        rts

; -------------------------------------
; NewLn - move crsr to next line
;
; affects: X, Y
;
; --- INTERNAL ---
; subtask of PrnChr
; -------------------------------------

NewLn   pha         ; save char
        ldx CV      ; get crsr row
        cpx SRE     ; end of scroll reg?
        beq NL1     ; yes -> branche
        cpx #$17    ; line 23?
        beq NLend   ; yes -> crsr stays
        ; --- normal wrap ---
        inx         ; increase line
        ldy #$00    ; begin of line
        jsr Plot
        jmp NLend
        ; --- scroll up ---
NL1     jsr UScrl
        ldy #$00    ; begin of line
        sty CH
NLend   pla         ; restore char
        rts

; -------------------------------------
; DEL - move crsr to the left and
;       delete char
;
; Can move through left margin.
;
; affects: A, X, Y
; -------------------------------------

DEL     jsr COff
        ldy CH
        lda lbPending
        beq DEL1
        ; pending
        jsr clPending
        jmp DELe

DEL1    dey
        bmi DEL2
        ; middle of line
        sty CH
        jmp DELe

DEL2    ; first col
        ldx CV
        beq DELee ; odd: top left corner
        dex
        ldy #79
        jsr Plot
        ldy CH

DELe    tya
        lsr          ; col DIV 2
        tay
        lda #" "|$80 ; clear char
        bcs DEL3     ; odd col?
        bit $c055
DEL3    sta (BASL),y
        bit $c054
DELee   jsr COn
        rts

; -------------------------------------
; clPending - clear pending flag
;
; affects: none
;
; Must be called in all crsr movement
; commands.
; -------------------------------------

clPending
        pha
        lda #$00
        sta lbPending
        pla
        rts

; -------------------------------------
; CUScrl - scroll up scrollregion
;
; affects: A, X, Y
;
; The crsr ist turned off during
; operation (COff - COn)
; -------------------------------------

CUScrl  jsr COff
        jsr UScrl
        jsr COn
        rts

; -------------------------------------
; UScrl - scroll up scrollregion
;
; affects: A, X, Y
; uses: xVector, zVector
; -------------------------------------

UScrl   ldx SRS     ; get first line
        ; --- scroll one line ---
US1     ; -- new line: --
        ; -- zVector --
        jsr SLV
        lda xVector ; screen line
        ldy xVector+1
        sta zVector
        sty zVector+1
        ; -- old line: --
        ; -- xVector --
        inx             ; old line
        jsr SLV
        ; -- copy even col chars --
        bit $c055
        ldy #$27        ; even col 39
US2     lda (xVector),y ; copy char
        sta (zVector),y
        dey
        bpl US2
        ; -- copy odd col chars --
        bit $c054
        ldy #$27        ; odd col 39
US3     lda (xVector),y ; copy char
        sta (zVector),y
        dey
        bpl US3
        cpx SRE         ; last line?
        bne US1         ; no -> go on
        jsr ErLn_       ; del last line

        rts

; -------------------------------------
; CDScrl - scroll down scrollregion
;
; affects: A, X, Y
;
; The crsr ist turned off during
; operation (COff - COn)
; -------------------------------------

CDScrl  jsr COff
        jsr DScrl
        jsr COn
        rts

; -------------------------------------
; DScrl - scroll down scrollregion
;
; affects: A, X, Y
; uses: xVector, zVector
; -------------------------------------

DScrl   ldx SRE     ; get last line
        ; --- scroll one line ---
DS1     ; -- new line: --
        ; -- zVector --
        jsr SLV
        lda xVector ; screen line
        ldy xVector+1
        sta zVector
        sty zVector+1
        ; -- old line: --
        ; -- xVector --
        dex             ; old line
        jsr SLV
        ; -- copy even col chars --
        bit $c055
        ldy #$27        ; even col 39
DS2     lda (xVector),y ; copy char
        sta (zVector),y
        dey
        bpl DS2
        ; -- copy odd col chars --
        bit $c054
        ldy #$27        ; odd col 39
DS3     lda (xVector),y ; copy char
        sta (zVector),y
        dey
        bpl DS3
        cpx SRS         ; first line?
        bne DS1         ; no -> go on
        jsr ErLn_       ; del first line

        rts

; -------------------------------------
; ErLn - erase screen line
;
; params: line number in X
; affects: A, X, Y
; return: $20 (space) in A
;
; For internal use:
; ErLn_ needs line ptr in xVector
; -------------------------------------

ErLn    jsr SLV ; line start in xVector

        ; -- erase even col chars --
ErLn_   bit $c055
        ldy #$27      ; even col 39
        lda #$20|$80  ; load space
EL1     sta (xVector),y ; clear char
        dey
        bpl EL1

        ; -- erase odd col chars --
        bit $c054
        ldy #$27      ; odd col 39
EL2     sta (xVector),y ; clear char
        dey
        bpl EL2

        rts

; -------------------------------------
; ErEnLn - erase to end of line
;
; affects: A, X, Y
;
; erase screen line from crsr to end of line
; -------------------------------------

ErEnLn
        ; -- erase even col chars --
        bit $c055
        lda CH        ; get crsr col
        lsr           ; col DIV 2
        tay
        sty tmp1      ; save start
        lda #$20|$80  ; load space
        bcs EEL2      ; odd crsr col
EEL1    sta (BASL),y  ; clear char
EEL2    iny
        cpy #$28      ; even pos 40?
        bne EEL1      ; next char

        ; -- erase odd col chars --
        bit $c054
        ldy tmp1      ; restore start
EEL3    sta (BASL),y  ; clear char
        iny
        cpy #$28      ; odd pos 40?
        bne EEL3      ; next char

        sta sCrsrChar ; del char ..
                      ; ..under crsr
        rts

; -------------------------------------
; ErBeLn - erase from begin of line
;
; affects: A, X, Y
;
; erase screen line up to crsr
; -------------------------------------

ErBeLn
        ; -- erase even col chars --
        bit $c055
        lda CH        ; get crsr col
        lsr           ; col DIV 2
        tay
        sty tmp1      ; save start
        lda #$20|$80  ; load space
EBL1    sta (BASL),y  ; clear char
        dey
        bpl EBL1      ; pos>=0 -> next

        ; -- erase odd col chars --
        bit $c054
        ldy tmp1      ; restore start
        bcc EBL3      ; even crsr col
EBL2    sta (BASL),y  ; clear char
EBL3    dey
        bpl EBL2      ; pos>=0 -> next

        sta sCrsrChar ; del char ..
                      ; ..under crsr
        rts

; -------------------------------------
; SLV - set line vector
; --- INTERNAL ---
;
; params: line no in X
; affects: A, Y
; return: screen line ptr in xVector
; -------------------------------------

SLV     lda LineVecLo,x
        ldy LineVecHi,x
        sta xVector
        sty xVector+1
        rts

LineVecLo
.byt $00, $80, $00, $80, $00, $80, $00, $80
.byt $28, $A8, $28, $A8, $28, $A8, $28, $A8
.byt $50, $D0, $50, $D0, $50, $D0, $50, $D0
LineVecHi
.byt $04, $04, $05, $05, $06, $06, $07, $07
.byt $04, $04, $05, $05, $06, $06, $07, $07
.byt $04, $04, $05, $05, $06, $06, $07, $07

; *************************************
; *
; * Init routines
; *
; *************************************

; -------------------------------------
; init memory
;
; -------------------------------------

InitVar lda #$00
        sta EMode
        sta EBufL
        sta SRS
        sta Font
        sta SaveF
        sta SaveR
        sta SaveRow
        sta SaveCol
        sta lbPending
        sta civis

        lda #$17    ; last line
        sta SRE     ; = 23

        rts

; -------------------------------------
; Init char
;
; -------------------------------------

InitChar
        rts

; -------------------------------------
; Exit char
;
; -------------------------------------

ExitChar
        rts

; -------------------------------------
; Init Screen
;
; -------------------------------------

InitScr
        ; --- turn on 80 col ---
        jsr $c300
        ; --- limit SET80COL-HISCR to text ---
        bit LORES
        ; --- erase screen ---
        ldx #$16      ; start at ln 22
IS1     txa
        pha           ; save X
        jsr ErLn      ; erase line
        pla
        tax           ; restore X
        dex           ; previous line
        bpl IS1
        ; --- put crsr ---
        ldx #$00
        ldy #$00
        jsr Plot

        rts

; -------------------------------------
; Exit Screen
;
; -------------------------------------

ExitScr
        ; --- erase screen ---
        jsr $fc58     ; clear current text screen
        rts

; *************************************
; *
; * ASCII tables
; *
; *************************************

; -------------------------------------
; table keyboard to ASCII
;
; This table is used to prepare keyboard
; input for sending over the serial
; line.
;
; ascii = $00 means ignore key
; ascii = $fe means do something
;             complicated (command key)
; -------------------------------------

kta ;_0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _a  _b  _c  _d  _e  _f

; --- Control chars ------------------------------------------------
;                                    {←}     {↓} {↑}
;        ^A  ^B  ^C  ^D  ^E  ^F  ^G  ^H  ^I  ^J  ^K  ^L  ^M  ^N  ^O
.byt $00,$01,$02,$03,$04,$05,$06,$07,$fe,$09,$fe,$fe,$0c,$0d,$0e,$0f  ; 0_
;                        {→}
;    ^P  ^Q  ^R  ^S  ^T  ^U  ^V  ^W  ^X  ^Y  ^Z  ^[  ^\  ^]  ^^  ^_
.byt $10,$11,$12,$13,$14,$fe,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f  ; 1_

; --- special chars ------------------------------------------------
;    ' '  !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /
.byt $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f  ; 2_
;     0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
.byt $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f  ; 3_

; --- capital letters ----------------------------------------------
;     @   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
.byt $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f  ; 4_
;     P   Q   R   S   T   U   V   W   X   Y   Z   [   \   ]   ^   _
.byt $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$5b,$5c,$5d,$5e,$5f  ; 5_

; --- lower case letters -------------------------------------------
;     `   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o
.byt $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f  ; 6_
;     p   q   r   s   t   u   v   w   x   y   z   {   |   }   ~  DEL
.byt $70,$fe,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$7b,$7c,$7d,$7e,$7f  ; 7_
