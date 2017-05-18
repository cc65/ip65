.feature labels_without_colons
.feature leading_dot_in_identifiers
.feature loose_char_term
.define .asc .byt

.export vt100_init_terminal         = InitTerminal
.export vt100_exit_terminal         = ExitTerminal
.export vt100_process_inbound_char  = ProcIn
.export vt100_process_outbound_char = ProcOut
.exportzp vt100_screen_cols         = 40
.exportzp vt100_screen_rows         = 25

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

; --- video RAM ---
Video = $84 ; $8400 - $87E7

; --- char ROM ---
Char = $8800 ; $8800 - $8fff

; --- colour values ---
; 0 black       8 orange
; 1 white       9 brown
; 2 red         a light red
; 3 cyan        b gray 1
; 4 purple      c gray 2
; 5 green       d light green
; 6 blue        e light blue
; 7 yellow      f gray 3

; --- font type ---
; vanilla     f  bold 1
; underline   e       3
fVa = $0f
fBo = $01
fUl = $0e
fUlBo = $03

; text background
bgcolour = $0b      ; gray1

; border colour
bgocolour = $0c     ; gray2

; -------------------------------------
; Zeropage Kernal
;
; Zeropage from $90 to $ff is used
; by kernal. 
; Following are the variables accessed
; by CaTer.
; -------------------------------------

; --- reverse mode ---
; 0 = normal, !0 = revers
Rvs = $c7

; --- crsr flag, 0 = on ---
sCrsrOn = $cc

; --- crsr blink counter ---
sCrsrCnt = $cd

; --- char under crsr ---
sCrsrChar = $ce

; --- crsr blink phase ---
; $00 = normal, $01 = revers
sCrsrPhase = $cf

; --- ptr to start of screen line ---
sLinePtr = $d1

; --- crsr column ---
sCol = $d3

; --- crsr row ---
sRow = $d6

; --- ptr to start of colour line ---
sLineColPtr = $f3

; -------------------------------------
; page $02, $03: BASIC and KERNAL 
;
; Following are the variables accessed
; by CaTer.
; -------------------------------------

; --- colour for writing ---
sColor = $0286

; --- colour under crsr ---
sCrsrCol = $0287

; --- video addr hibyte ---
VideoAddr = $0288

; --- CTRL, SHIFT, C= ---
; flags indicating pressed
; contol keys
; 1 SHIFT, 2 C=, 4 CTRL
ControlFlags = $028d

; --- flag for SHIFT + C= ---
; $80 = lock, no charset switch
; $00 = free
ShiftCFlag = $0291

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
yVector = ptr2
xVector = ptr3
wVector = ptr4

; --- vector for PrnScr ---
; tmp1, tmp2
vVector = tmp1

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
; bit 6 = background set
; bit 7 = foreground set
Font .res 1
; foreground
AFore .res 1
; background
ABack .res 1

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
        lda atp,y   ; ASCII to PETSCII
        beq PIrts   ; ignore $00
        cmp #$01    ; something special?
        beq Special
        jsr CPrnChr ; print to screen
PIrts   rts

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
        ldx sRow    ; get row
        ldy #$00    ; set col=0
        jsr CPlot   ; set crsr
        rts
; --- BS ---
D1      cmp #$08    ; BS?
        bne D2
BS      jsr clPending
        ldy sCol    ; get col
        beq D1rts   ; stop @ left margin
        dey         ; dec column
        ldx sRow    ; get row
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
        ldx sRow    ; crsr line
        cpx SRE     ; end scroll region?
        bne D4a     ;  no -> branch
        jsr CUScrl  ;  yes -> scroll up
        rts
D4a     cpx #$18    ; end of screen?
        bne D4b     ;  no -> branch
        rts         ;  yes -> do nothing
D4b     inx         ; next line
        ldy sCol    ; get col
        jsr CPlot   ; set crsr
        rts
; --- TAB ---
D5      cmp #$09    ; TAB?
        bne D6
        ; don't clear pending
        ; don't set pending
        lda sCol    ; crsr col
        and #$f8    ; (col DIV 8) * 8
        clc         ; col + 8
        adc #$08
        cmp #$28    ; col=40?
        bne D5a     ; no -> skip
        lda #$27    ; yes -> col=39
D5a     tay         ; col to y
        ldx sRow    ; line to x
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
        ldx sRow    ; get crsr row
        cpx SRS     ; top os scroll reg?
        bne E6a
        jsr CDScrl  ; yes -> scroll down
        jmp Eend
E6a     cpx #$00    ; top of screen?
        bne E6b
        jmp Eend    ; yes -> do nothing
E6b     dex         ; one line up
        ldy sCol    ; get crsr col
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
        lda Rvs     ; save reverse mode
        sta SaveR
        ldx sRow    ; save position
        ldy sCol
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
        sta Rvs     ; .. reverse mode
        ldx SaveF   ; restore font
        stx Font
        lda FontTable,x
        sta sColor  ; set colour
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
LE1c    lda sRow    ; get crsr row
        sec
        sbc EPar    ; row = row - up
        cmp SRS     ; stop at top of ..
        bpl LE1a    ; ..scroll region
        lda SRS
LE1a    tax         ; x is row
        ldy sCol    ; y is col
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
LE2c    lda sRow    ; get crsr row
        clc
        adc EPar    ; row = row + down
        cmp SRE     ; outside scrregion?
        bcs LE2d    ; yes -> branch
        tax         ; x is row
        jmp LE2a
LE2d    ldx SRE     ; x = row = SRE
LE2a    ldy sCol    ; y is col
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
LE3c    lda sCol    ; get crsr col
        clc
        adc EPar    ; col = col + right
        cmp #$27    ; outside screen?
        bcs LE3d    ; yes -> branch
        tay
        jmp LE3a
LE3d    ldy #$27    ; y=col=left margin
LE3a    ldx sRow    ; x is row
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
LE4c    lda sCol    ; get crsr col
        sec
        sbc EPar    ; col = col - left
        bpl LE4a    ; stop at left..
        lda #$00    ; ..margin
LE4a    tay         ; y is col
        ldx sRow    ; x is row
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
        bne LE5e
        ora #$01    ; bit 0 = reverse
        jmp LE5nx
LE5e    ; -- 30 - 37 --
        cpy #38     ; >= 38?
        bcs LE5g
        cpy #30     ; < 30?
        bcc LE5g
        tya
        sbc #30
        sta AFore
        lda Font
        ora #$80    ; bit 7 = fore
        jmp LE5nx
LE5g    ; -- 40 - 47 --
        cpy #48     ; >= 48?
        bcs LE5nx
        cpy #40     ; < 40?
        bcc LE5nx
        tya
        sbc #40
        sta ABack
        lda Font
        ora #$40    ; bit 6 = back
LE5nx   ; -- next char --
        sta Font
        pla         ; get nondigit char
        cmp #$3b    ; is semicolon?
        beq LE5a    ; then next param
        ; -- set colour --
        lda Font
        ; set foreground
        bpl LE5h
        ldx AFore
        lda AColTab,x
        ; avoid black or white foregr if
        ; backgr is given and not black
        tax
        lsr         ; 0(blk) or 1(wht)?
        bne LE5j    ; no -> keep fore
        bit Font    ; back? (bit 6 -> v)
        bvc LE5j    ; no -> keep fore
        lda ABack   ; back is black?
        bne LE5hh   ; no -> take back
LE5j    txa
        ; ^^^ end of avoid ^^^
        ldx #$00    ; reverse off
        jmp LE5k
LE5h    ; set background
        bit Font    ; bit 6 -> v
        bvc LE5i
LE5hh   ldx ABack
        lda AColTab,x
        ldx #$01    ; reverse on
        jmp LE5k
LE5i    ; set ANSI font attributes
        ldx #$00    ; reverse off
        lsr         ; reverse?
        bcc LE5l
        inx         ; -> reverse on
LE5l    tay
        lda FontTable,y
LE5k    sta sColor  ; set colour
        stx Rvs     ; set reverse mode
        jmp LEend

FontTable    ; bits mean ul bo
.byt fVa, fBo         ; 00 01
.byt fUl, fUlBo       ; 10 11

AColTab
;ANSI 30  31  32  32  34  35 36  37
;    blk red grn  ye blu mag cy  wh
.byt  0, 10,  5,  7, 14,  4,  3,  1

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
        ldx sRow      ; line in X
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
        cpy #$19    ; >= 25?..
        bcs LE8d    ; ..error!
        sty xVector ; save row
        ; -- prepare col
        jsr GetNum
        ldy EPar    ; get col
        bne LE8c    ; 0 means 1
        iny
LE8c    dey         ; col 1 -> col 0
        cpy #$28    ; >= 40?..
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
        ldx sRow      ; get crsr line
LE9b    inx           ; next line
        cpx #$19      ; line 25?
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
        ldx sRow      ; get crsr line
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
        ldx #$18      ; start at ln 24
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
        cpy #$19    ; >=25?..
        bcs LE10e   ; ..error!
        sty xVector ; save top
        ; -- prepare bottom --
        jsr GetNum
        ldy EPar    ; get bottom
        dey         ; line 1 -> line 0
        cpy #$19    ; >=25?..
        bcs LE10e   ; ..error!
        sty yVector ; save bottom
        ; -- validate lines --
        lda xVector ; restore top
        cmp yVector ; >= bottom?..
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
        lda pta,y   ; PETSCII to ASCII
        beq POrts   ; ignore key
        cmp #$ff
        beq StrKey  ; send a string
        cmp #$fe
        beq CmdKey  ; command key
        jsr putRS
POrts   rts

; -------------------------------------
; outgoing string
;
; params: key in y
; -------------------------------------

ScrsrU .byt $1b, $5b, $41, $00 ; esc [ A
ScrsrD .byt $1b, $5b, $42, $00 ; esc [ B
ScrsrR .byt $1b, $5b, $43, $00 ; esc [ C
ScrsrL .byt $1b, $5b, $44, $00 ; esc [ D

StrKey  tya         ; restore key

; --- crsr U ---
K1      cmp #$91    ; test crsr U
        bne K2
        ldx #<ScrsrU
        ldy #>ScrsrU
        jsr SendStr
        rts
; --- crsr L ---
K2      cmp #$9d    ; test crsr L
        bne K3
        ldx #<ScrsrL
        ldy #>ScrsrL
        jsr SendStr
K3      rts

; -------------------------------------
; outgoing command key
;
; -------------------------------------

CmdKey  tya         ; restore character

; --- crsr R ---
; ---   ^]   ---
; both events send $1d
        cmp #$1d
        bne C0
        lda #$04    ; test control Key
        bit ControlFlags
        beq crsrR   ; not pressed
        ; control ] is pressed
        tya         ; send ^]
        jsr putRS
        rts

        ; crsr R
crsrR   ldx #<ScrsrR
        ldy #>ScrsrR
        jsr SendStr
        rts

; --- crsr D ---
; ---   ^Q   ---
; both events send char $11
C0      cmp #$11    ;^Q / crsr down
        bne C8
        lda #$04    ; test control Key
        bit ControlFlags
        beq crsrD   ; not pressed
        ; control Q is pressed
        tya         ; send ^Q
        jsr putRS
        rts

        ; crsr down is pressed
crsrD   ldx #<ScrsrD
        ldy #>ScrsrD
        jsr SendStr
        rts

; --- HOME key ---
; ---    ^S    ---
; both events send char $13
C8      cmp #$13    ;^S / HOME
        bne C9
        lda #$04    ; test control Key
        bit ControlFlags
        beq C8Home  ; not pressed
        ; control S is pressed
        tya         ; send ^S
        jsr putRS
        rts

        ; send TAB
C8Home  lda #$09
        jsr putRS
        rts

; --- HOME key ---
; ---    ^T    ---
; both events send char $14
C9      cmp #$14    ;^S / DEL
        bne C10
        lda #$04    ; test control Key
        bit ControlFlags
        beq C9Del   ; not pressed
        ; control T is pressed
        tya         ; send ^T
        jsr putRS
        rts

        ; send TAB
C9Del   lda #$08
        jsr putRS
        rts

; --- C=Q ---
; quit CaTer
C10     cmp #$ab    ; C=Q
        bne C12
        jsr telnet_close
        rts

; --- unknown C=-Key ---
C12     rts

; *************************************
; *
; * screen handling
; *
; *************************************

; Variables controlling the cursor
;
;                             COff
;                     Kernal  COon Plot
; sCrsrOn       $cc     r      x
; sCrsrCnt      $cd     r/w    x
; sCrsrPhase    $cf     r/w    x
; sCol          $d3     r           x
; sRow          $d6                 x
; sLinePtr      $d1     r           x
; sLineColPtr   $f3     r/w         x
; sCrsrChar     $ce     r/w    x
; sCrsrCol      $0287   r/w    x
; sColor        $0286   r

; Cursor blink phases:
; on (sCrsrPhase = $01)
;   char on screen = revers of sCrsrChar
;   color on screen = sColor
; off (sCrsrPhase = $00)
;   char on screen = sCrsrChar
;   color on screen = sCrsrCol

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
        ldy #$02       ; prevent soon..
        sty sCrsrCnt   ; ..blink
        sty sCrsrOn    ; crsr off
        lda sCrsrPhase ; crsr revers?
        beq CO2        ; no -> return
        dey            ; normal phase
        sty sCrsrPhase
        ldy sCol       ; get column
        lda sCrsrChar  ; restore char
        sta (sLinePtr),y
        lda sCrsrCol   ; restore colour
        sta (sLineColPtr),y

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
        bne COn1         ; -> do nothing
        ldy sCol         ; get column
        lda (sLinePtr),y ; save chr
        sta sCrsrChar
        eor #$80         ; reverse char
        sta (sLinePtr),y
        lda (sLineColPtr),y; save colour
        sta sCrsrCol
        lda sColor     ; set crsr colour
        sta (sLineColPtr),y
        lda #$14       ; set counter...
        sta sCrsrCnt   ; ... to max
        ldy #$01       ; set rvs phase
        sty sCrsrPhase
        dey            ; cursor on
        sty sCrsrOn

COn1    pla
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

Plot    stx sRow     ; set row
        sty sCol     ; set col
        jsr SLV
        ldx xVector ; set screen line
        ldy xVector+1
        stx sLinePtr
        sty sLinePtr+1
        ldx yVector ; set color line
        ldy yVector+1
        stx sLineColPtr
        sty sLineColPtr+1
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
; PrnChr - print char (petscii) to screen
;
; params: chr in A, $80 means no output
; affects: A
; uses: xVector
;
; Rem: The char π/~ is read from
; keyboard as $de but from screen
; (basic code, via input) as $ff.
; -------------------------------------

PrnChr  sta xVector ; save char
        txa         ; save registers
        pha
        tya
        pha
        lda xVector ; restore char

        ; PETSCII to ScreenCode (SC)
        ; -- $ff -- π/~ from keybd
        cmp #$ff      ; warn: reverse
        bne PC_1
        lda #$de
        jmp PCrvs
        ; -- $e0-$fe -- upper graphics
PC_1    cmp #$e0      ; no output
        bcc PC0
        jmp PCend
        ; -- $c0-$df -- capital letters
PC0     cmp #$c0
        bcc PC1
        and #$7f
        jmp PCrvs
        ; -- $a0-$bf -- graphics/latin-9
PC1     cmp #$a0
        bcc PC2
        and #$3f
        ora #$40
        jmp PCrvs
        ; -- $80-$9f -- upper control
PC2     cmp #$80      ; no output
        bcc PC3
        jmp PCend
        ; -- $60-$7f -- lower capital
PC3     cmp #$60 ; for string constants
        bcc PC4
        and #$5f
        jmp PCrvs
        ; -- $40-$5f -- small letters
PC4     cmp #$40
        bcc PC5
        and #$1f
        jmp PCrvs
        ; -- $20-$3f -- numbers
PC5     cmp #$20
        bcc PC6
        jmp PCrvs
        ; -- $00-$1f -- lower control
PC6     jmp PCend     ; no output

        ; -- handle reverse mode --
PCrvs   ldx Rvs     ; reverse mode?
        beq PCput
        eor #$80    ; reverse char

PCput   ldx lbPending   ; need new line?
        beq PC7         ; no -> skip
        ldx #$00        ; clear pending
        stx lbPending
        jsr NewLn
PC7     ldy sCol        ; get crsr col
        sta (sLinePtr),y; char to screen
        lda sColor      ; get colour
        sta (sLineColPtr),y ; set colour

        ; -- move on crsr --
        cpy #$27        ; col = 39?
        bne PC8         ; no -> skip
        lda #$ff        ; yes -> set..
        sta lbPending   ; ..pending
        jmp PCend
PC8     iny             ; move on crsr
        sty sCol

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
        ldx sRow    ; get crsr row
        cpx SRE     ; end of scroll reg?
        beq NL1     ; yes -> branche
        cpx #$18    ; line 24?
        beq NLend   ; yes -> crsr stays
        ; --- normal wrap ---
        inx         ; increase line
        ldy #$00    ; begin of line
        jsr Plot
        jmp NLend
        ; --- scroll up ---
NL1     jsr UScrl
        ldy #$00    ; begin of line
        sty sCol
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
        ldy sCol
        lda lbPending
        beq DEL1
        ; pending
        jsr clPending
        jmp DELe

DEL1    dey
        bmi DEL2
        ; middle of line
        sty sCol
        jmp DELe

DEL2    ; first col
        ldx sRow
        beq DELee ; odd: top left corner
        dex
        ldy #39
        jsr Plot
        ldy sCol

DELe    lda #" "  ; clear char
        sta (sLinePtr),y
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
; uses: xVector, yVector,
;       zVector, wVector
; -------------------------------------

UScrl   ldx SRS     ; get first line
        ; --- scroll one line ---
US1     ; -- new line: --
        ; -- zVector and wVector --
        jsr SLV
        lda xVector ; screen line
        ldy xVector+1
        sta zVector
        sty zVector+1
        lda yVector ; colour line
        ldy yVector+1
        sta wVector
        sty wVector+1
        ; -- old line: --
        ; -- xVector and yVector
        inx             ; old line
        jsr SLV
        ; -- copy chars and colours --
        ldy #$27        ; col 39
US2     lda (xVector),y ; copy char
        sta (zVector),y
        lda (yVector),y ; copy colour
        sta (wVector),y
        dey
        bpl US2
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
; uses: xVector, yVector,
;       zVector, wVector
; -------------------------------------

DScrl   ldx SRE     ; get last line
        ; --- scroll one line ---
DS1     ; -- new line: --
        ; -- zVector and wVector --
        jsr SLV
        lda xVector ; screen line
        ldy xVector+1
        sta zVector
        sty zVector+1
        lda yVector ; colour line
        ldy yVector+1
        sta wVector
        sty wVector+1
        ; -- old line: --
        ; -- xVector and yVector
        dex             ; old line
        jsr SLV
        ; -- copy chars ond colours --
        ldy #$27        ; col 39
DS2     lda (xVector),y ; copy char
        sta (zVector),y
        lda (yVector),y ; copy colour
        sta (wVector),y
        dey
        bpl DS2
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
; and line colot ptr in yVector
; -------------------------------------

ErLn    jsr SLV ; line start in xVector
                ; col  start in yVector

        ; -- erase chars --
ErLn_   ldy #$27      ; col 39
        lda #$20      ; load space
EL1     sta (xVector),y ; clear char
        dey
        bpl EL1

        ; -- set colour --
        ldy #$27      ; col 39
        lda #fVa      ; load vanilla
EL2     sta (yVector),y ; clear char
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
        ; -- erase chars --
        ldy sCol      ; get crsr col
        lda #$20      ; load space
EEL1    sta (sLinePtr),y ; clear char
        iny
        cpy #$28      ; pos 40?
        bne EEL1      ; next char
        sta sCrsrChar ; del char ..
                      ; ..under crsr
        ; -- set colour --
        ldy sCol      ; get crsr col
        lda #fVa      ; load vanilla
EEL2    sta (sLineColPtr),y ; set colour
        iny
        cpy #$28      ; pos 40?
        bne EEL2      ; next char

        rts

; -------------------------------------
; ErBeLn - erase from begin of line
;
; affects: A, X, Y
;
; erase screen line up to crsr
; -------------------------------------

ErBeLn
        ; -- erase chars --
        ldy sCol      ; get crsr col
        lda #$20      ; load space
EBL1    sta (sLinePtr),y ; clear char
        dey
        bpl EBL1      ; pos>=0 -> next
        sta sCrsrChar ; del char ..
                      ; ..under crsr
        ; -- set colour --
        ldy sCol      ; get crsr col
        lda #fVa      ; load vanilla
EBL2    sta (sLineColPtr),y ; clear char
        dey
        bpl EBL2      ; pos>=0 -> next

        rts

; -------------------------------------
; SLV - set line vectors
; --- INTERNAL ---
;
; params: line no in X
; affects: A, Y
; return: screen line ptr in xVector
;         screen color ptr in yVector
; -------------------------------------

SLV     lda $ecf0,x   ; get lo byte
        sta xVector
        sta yVector
        ; determin hi byte
        ldy #Video    ; hi byte
        cpx #$07      ; line < 7?
        bcc SLV1
        iny
        cpx #$0d      ; line < 13?
        bcc SLV1
        iny
        cpx #$14      ; line < 20?
        bcc SLV1
        iny           ; line 20-24
SLV1    sty xVector+1
        tya
        clc
        adc #$d8-Video
        sta yVector+1

        rts

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

        lda #$18    ; last line
        sta SRE     ; = 24

        rts

; -------------------------------------
; Init char
;
; at the end the font is apended.
; it is copied to $8800 and enabled
;
; uses: xVector, yVector, zVector
; -------------------------------------

; begin of reverse chars
Reverse = Char + $0400

InitChar
; enable font
        sei
        ldx #<FontROM ; Font in zVector
        ldy #>FontROM
        stx zVector
        sty zVector+1
        ldx #<Char    ; Char in yVector
        ldy #>Char
        stx yVector
        sty yVector+1
        ldx #<Reverse ; Revrs in xVector
        ldy #>Reverse
        stx xVector
        sty xVector+1

; copy font
        ldx #$04      ; copy 4 pages
        ldy #$00
IC1     lda (zVector),y
        sta (yVector),y
        eor #$ff      ; reverse char
        sta (xVector),y
        iny
        bne IC1
        ; switch to next page
        inc zVector+1
        inc yVector+1
        inc xVector+1
        dex
        bne IC1

; enable font
        lda $dd00
        and #$fc
        ora #$01
        sta $dd00
        lda $d018
        and #$f1
        ora #$02
        sta $d018
        lda #Video
        sta VideoAddr
        cli
        rts

; -------------------------------------
; Exit char
;
; -------------------------------------

ExitChar
; disable font
        sei
        lda $dd00
        and #$fc
        ora #$03
        sta $dd00
        lda $d018
        and #$f1
        ora #$04
        sta $d018
        lda #04
        sta VideoAddr
        cli
        rts

; -------------------------------------
; Init Screen
;
; -------------------------------------

InitScr
        ; --- set background ---
        lda #bgocolour
        sta $d020
        lda #bgcolour
        sta $d021
        ; --- disable Shift C= ---
        lda #$80
        sta ShiftCFlag
        ; --- erase screen ---
        ldx #$18      ; start at ln 24
IS1     txa
        pha           ; save X
        jsr ErLn      ; erase line
        pla
        tax           ; restore X
        dex           ; previous line
        bpl IS1
        lda #fVa     ; load vanilla
        sta sColor
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
        ; --- set background ---
        lda #$fe
        sta $d020
        lda #$f6
        sta $d021
        ; --- ensable Shift C= ---
        lda #$00
        sta ShiftCFlag
        ; --- erase screen ---
        lda #$fe
        sta sColor
        sta sCrsrCol
        jsr $e544
        rts

; *************************************
; *
; * ASCII and PETSCII tables
; *
; *************************************

; -------------------------------------
; table ASCII to PETSCII
;
; This tabel is used to convert incoming
; ASCII chars.
;
; pet=$00 means ignore the char
; pet=$01 do something complicated: C
;         PETSCII and ASCII equal:  =
;         PETSCII and ASCII differ: /
; -------------------------------------

atp ;_0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _a  _b  _c  _d  _e  _f

; --- Control chars ------------------------------------------------
;    NUL                     ACK BEL BS  TAB LF          CR
;                                 C   C   C   C           C
.byt $00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$01,$00,$00  ; 0_
;                        NAK                     ESC
;                                                 C
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00  ; 1_

; --- ASCII = PETSCII ----------------------------------------------
;    ' '  !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /
.byt $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f  ; 2_
;     0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
.byt $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f  ; 3_

; --- upper case letters -------------------------------------------
;     @   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
;     =   /   /   /   /   /   /   /   /   /   /   /   /   /   /   /
.byt $40,$c1,$c2,$c3,$c4,$c5,$c6,$c7,$c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf  ; 4_
;     P   Q   R   S   T   U   V   W   X   Y   Z   [  \£   ]  ^↑  _←
;     /   /   /   /   /   /   /   /   /   /   /   =   =   =   =   =
.byt $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$da,$5b,$5c,$5d,$5e,$5f  ; 5_

; --- lower case letters -------------------------------------------
;    `━   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o
;     /   /   /   /   /   /   /   /   /   /   /   /   /   /   /   /
.byt $c0,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f  ; 6_
;     p   q   r   s   t   u   v   w   x   y   z  {╋  |▒  }┃  ~▒▒ DEL
;     /   /   /   /   /   /   /   /   /   /   /   /   /   /   /
.byt $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$db,$dc,$dd,$de,$00  ; 7_

;    --- upper control codes ---------------------------------------
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 8_
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 9_

;    --- latin 9 chars ---------------------------------------------
;    NBSP         £   €      (Š)  §  (š)  ©       «       -
.byt $20,$df,$df,$bf,$be,$df,$d3,$b5,$53,$bb,$df,$bc,$df,$2d,$df,$df  ; a_
;     °   ±   ²   ³  (Ž)  µ          (ž)          »   Œ   œ  (Ÿ)
.byt $ba,$b8,$b6,$b7,$da,$b9,$df,$df,$5a,$df,$df,$bd,$b0,$b0,$d9,$df  ; b_
;     À  (Á)  Â  (Ã)  Ä   Å      (Ç)  È   É   Ê  (Ë) (Ì) (Í) (Î) (Ï)
.byt $a5,$c1,$a4,$c1,$a3,$a4,$df,$c3,$ad,$ab,$ac,$c5,$c9,$c9,$c9,$c9  ; c_
;    (Ð) (Ñ) (Ò) (Ó)  Ô  (Õ)  Ö      (Ø) (Ù) (Ú) (Û)  Ü  (Ý)      ß
.byt $c4,$ce,$cf,$cf,$b1,$cf,$af,$df,$cf,$d5,$d5,$d5,$b3,$d9,$df,$b4  ; d_
;     à  (á)  â  (ã)  ä   å       ç   è   é   ê   ë  (ì) (í) (î) (ï)
.byt $a2,$41,$a1,$41,$a0,$a1,$df,$a6,$aa,$a8,$a9,$a7,$49,$49,$49,$49  ; e_
;        (ñ) (ò) (ó)  ô  (õ)  ö      (ø) (ù) (ú) (û)  ü  (ý)     (ÿ)
.byt $df,$4e,$4f,$4f,$b1,$4f,$ae,$df,$4f,$55,$55,$55,$b2,$59,$df,$59  ; f_

; -------------------------------------
; table PETSCII to ASCII
;
; This table is used to prepare keyboard
; input for sending over the serial
; line.
;
; ascii = $00 means ignore key
; ascii = $ff menas send string
; ascii = $fe means do something
;             complicated (command key)
; -------------------------------------

pta ;_0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _a  _b  _c  _d  _e  _f

; --- Control chars ------------------------------------------------
;               {STOP}                                {RETURN}
;        ^A  ^B  ^C  ^D  ^E  ^F  ^G  ^H  ^I  ^J  ^K  ^L  ^M  ^N  ^O
.byt $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f  ; 0_
;      {crsr↓} {HOME|DEL}                              {crsr→}
;    ^P  ^Q  ^R  ^S  ^T  ^U  ^V  ^W  ^X  ^Y  ^Z  ^[  ^\£ ^]  ^↑
.byt $10,$fe,$12,$fe,$fe,$15,$16,$17,$18,$19,$1a,$1b,$1c,$fe,$1e,$1f  ; 1_

; --- ASCII = PETSCII ----------------------------------------------
;    ' '  !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /
.byt $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f  ; 2_
;     0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
.byt $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f  ; 3_

; --- lower case letters -------------------------------------------
;     @   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o
;     =   /   /   /   /   /   /   /   /   /   /   /   /   /   /   /
.byt $40,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f  ; 4_
;     p   q   r   s   t   u   v   w   x   y   z   [  \£   ]  ^↑   ←
;     /   /   /   /   /   /   /   /   /   /   /   =   =   =   =  ESC
.byt $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$5b,$5c,$5d,$5e,$1b  ; 5_

; --- mirror of upper letters - should never appear ----------------
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 6_
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 7_

; --- upper control chars ------------------------------------------
;                        {f1}{f3}{f5}{f7}{f2}{f4}{f6}{f8}{ShRET}
;
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 8_
;      {crsr↑} {CLR}{INS}                              {crsr←}
;                    DEL
.byt $00,$ff,$00,$00,$7f,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$00,$00  ; 9_

; --- block graphics -----------------------------------------------
;   ShSP C=K C=I C=T C=@ C=G C=+ C=M C=£ Sh£ C=N C=Q C=D C=Z C=S C=P
;                                         |
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$7c,$00,$fe,$00,$00,$00,$00  ; a_
;    C=A C=E C=R C=W C=H C=J C=L C=Y C=U C=O Sh@ C=F C=C C=X C=V C=B
;                                             `
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$60,$00,$00,$00,$00,$00  ; b_

; --- capital letters ----------------------------------------------
;    Sh*  A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
;     _   /   /   /   /   /   /   /   /   /   /   /   /   /   /   /
.byt $5f,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f  ; c_
;     P   Q   R   S   T   U   V   W   X   Y   Z  Sh+ C=- Sh-  π  C=*
;     /   /   /   /   /   /   /   /   /   /   /   {       }   ~
.byt $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$7b,$00,$7d,$7e,$00  ; d_

; --- mirror of block graphics - should never appear ---------------
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; e_
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; f_

; --- Font ROM ------------------------

FontROM
.incbin "c64vt100font.bin"
