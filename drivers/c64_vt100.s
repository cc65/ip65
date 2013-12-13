; vt100 emulation for C64
; vt100 emulation for C64
; originally from CaTer - Copyright Lars Stollenwerk 2003
; CaTer homepage is http://formica.nusseis.de/Cater/
; converted for use with ip65 by Jonno Downes, 2009.
; this version is for C64 only
; CaTer originally licensed under GPL
; Lars Stollenwerk has agreed to relicense the code in this file under MPL (Oct 2009)
;
; to use:
; 1) call vt100_init_terminal
; 2) for every 'inbound' data (received from remote host), call "vt100_process_inbound_char" - this will update the screen
; 3) pass every keypress into vt100_transform_outbound_char. on return from this call,
;      Y = 0 means don't send anything as a result of this keypress
;      Y = 1 means A contains single character to send to remote host
;      Y = 2 means AX points at null terminated string to send to remote host (e.g. an ANSI escape sequence)



.include "../inc/common.i"

.export vt100_init_terminal
.export vt100_process_inbound_char
.export vt100_transform_outbound_char

.import beep

; --- colour values ---
col_black       = $00
col_white       = $01
col_red         = $02
col_cyan        = $03
col_purple      = $04
col_green       = $05
col_blue        = $06
col_yellow      = $07
col_orange      = $08
col_brown       = $09
col_light_red   = $0a
col_gray_1      = $0b
col_gray_2      = $0c
col_light_green = $0d
col_light_blue  = $0e
col_gray_3      = $0f

; --- colours ---
; vanilla     f  bold 1
; underline   e       3
; blink       5       d
; blink uline a       7
charmode_vanilla = $0f
charmode_bold = $01
charmode_underline = $0e
charmode_underline_bold = $03
charmode_blink = $05
charmode_blink_bold = $0d
charmode_blink_underline = $0a
charmode_blink_underline_bold = $07

; text background 
text_background_colour = col_black


.segment "APP_SCRATCH" 
escape_buffer: .res $100


.zeropage

; --- esc mode ---
; $00 = normal
; $0f = esc mode
; $ff = esc [ mode
; $f0 = ignore one char
escape_mode: .res 1

; --- Vector ---
; four vectors in zeropage 
; for temporary use
temp_ptr_z: .res 2
temp_ptr_y: .res 2
temp_ptr_x: .res 2
temp_ptr_w: .res 2

escape_buffer_length: .res 1  ; points to first free position
escape_parameter: .res 1       ; numeric parameter in esc sequence
scroll_region_start: .res 1
scroll_region_end: .res 1


; font_mode contains three bits
; bit 0 = bold
; bit 1 = underline
; bit 2 = blink
; bit 7 = direct ANSI ESC colour
font_mode: .res 1

direct_colour: .res 1

; --- crsr save area ---
; here is crsr info saved with 
; ESC 7 and restored from with
; ESC 8

saved_font_mode:  .res 1
saved_reverse_mode:  .res 1
saved_row:  .res 1
saved_column:  .res 1

print_ptr: .res 2 ;temp vector for printing to screen





; -------------------------------------
; memory map
;
; -------------------------------------

; --- screen --- 
; $0400 - $07ff
Screen = $0400

; --- escape buffer --- 
; $0800 - $0bff

; --- char --- 
; $2000 - $27ff
font_table = $2000

; -------------------------------------
; constant declaration
;
; -------------------------------------

esc = $1b
brace = $5b

.code

;intialize VT100 emulation state
;inputs: none
;outputs: none
vt100_init_terminal:

  jsr initialise_variables ; init memory variables
  jsr initialise_font; init font
  jsr initialise_screen ; init screen
  rts
  
;process incoming character
;inputs:
; A is inbound character
;outputs: 
; none, but screen and/or terminal state is updated.

vt100_process_inbound_char:
  tay
  lda escape_mode   ; handle esc mode
  beq :+            ; to far for branch to escape
  jmp handle_escape_char
:        
  lda ascii_to_petscii,y         ; ASCII to PETSCII
  beq @done         ; ignore non-printing chars     
  cmp #$01          ; something special?
  beq handle_special_char        
  jsr print_to_screen ; print to screen        
@done:
  rts



do_cr:
  ldx $d6     ; get row
  ldy #$00    ; set col=0
  jsr cursor_plot   ; set crsr
  rts
                     
do_line_feed:
  ldx $d6     ; crsr line
  cpx scroll_region_end     ; end scroll region?
  bne down_one_line    ;  no -> go on
  jsr cursor_off
  jsr scroll_up_scrollregion   ;  yes -> scroll up
  jsr cursor_on
  rts

handle_special_char:
  tya         ; restore original char
  cmp #$0d    ; CR?
  beq do_cr
 
  cmp #$08    ; BS?
  bne @not_bs
  ldy $d3     ; get col
  beq @bs_done   ; stop at left margin
  dey         ; dec column
  ldx $d6     ; get row
  jsr cursor_plot   ; set crsr
@bs_done:
  rts
@not_bs:
  cmp #$1b    ; esc?
  bne @not_escape
  lda #$0f    ; set esc mode
  sta escape_mode
  rts
@not_escape:
  cmp #$07    ; BEL?
  bne @not_bell  
  jsr beep
  rts
@not_bell:
  cmp #$0a    ; LF?
  beq do_line_feed
 
@not_lf:
  cmp #$09    ; TAB?
  bne @not_tab
  lda $d3     ; crsr col
  and #$f8    ; (col DIV 8) * 8
  clc         ; col + 8
  adc #$08
  cmp #$28    ; col=40?
  bne @not_last_col     ; no -> skip
  lda #$27    ; yes -> col=39
@not_last_col:
  tay         ; col to y
  ldx $d6     ; line to x
  jsr cursor_plot   ; set crsr
  rts

@not_tab:
  rts        

down_one_line:
  cpx #$18    ; end of screen?
  bne @not_end_of_screen     ;  no -> go on
  rts         ;  yes -> do nothing
@not_end_of_screen:
  inx         ; next line
  ldy $d3     ; get col
  jsr cursor_plot   ; set crsr
  rts        


; esc mode
; data in Y
; escape_mode <> $00 in A
handle_escape_char:
  tax         ; save escape_mode
  and #$0f    ; escape_mode = $0f?
  bne @not_discard_mode

; --- discard mode --- escape_mode = $f0
;discard char
  lda #$00    ; reset escape_mode
  sta escape_mode
  rts

@not_discard_mode:
  txa         ; restore escape_mode
  and #$f0    ; escape_mode = $ff?
  beq @short_escape_mode    ; no -> short Emode
  jmp long_escape_mode    ; yes -> long Emode
  
; short esc mode
; escape_mode = $0f
; process first char
@short_escape_mode:
  tya         ; restore char
; --- [ ---
  cmp #brace  ; [ ?
  bne @not_brace
  lda #$ff    ; set esc [ mode
  sta escape_mode
  rts
; --- ( ---
@not_brace:
        cmp #$28    ; ( ?
        bne :+
        jmp set_discard_mode
; --- ) ---
: 
  cmp #$29    ; ) ?
  bne :+
  jmp set_discard_mode
; --- # ---
:
  cmp #$23    ; # ?
  bne :+
  jmp set_discard_mode
; --- D --- index 
:
    cmp #$44    ; D ?
    bne :+
    jsr do_line_feed      ; same as LF
    jmp done_escape
; --- M --- reverse index
:
  cmp #$4d    ; M ?
  bne @not_M
  ldx $d6     ; get crsr row
  cpx scroll_region_start     ; top of scroll reg?
  bne :+
  jsr cursor_off    ; yes -> scroll down
  jsr scroll_down_scrollregion  
  jsr cursor_on
  jmp done_escape
:
  cpx #$00    ; top of screen?
  bne :+
  jmp done_escape    ; yes -> do nothing
:     
  dex         ; one line up
  ldy $d3     ; get crsr col
  jsr cursor_plot   ; set crsr
  jmp done_escape

@not_M:
; --- E --- next line
  cmp #$45    ; E ?
  bne :+
  jsr do_cr
  jsr do_line_feed
  jmp done_escape
:
; --- 7 --- save crsr
  cmp #$37    ; 7?
  bne :+
  lda font_mode    ; save font
  sta saved_font_mode
  lda $c7     ; save reverse mode
  sta saved_reverse_mode
  ldx $d6     ; save position
  ldy $d3
  stx saved_row
  sty saved_column
  jmp done_escape
:      
; --- 8 --- restore crsr
  cmp #$38    ; 8?
  bne :+
  ldx saved_row ; restore pos
  ldy saved_column
  jsr cursor_plot
  lda saved_reverse_mode   ; restore ..
  sta $c7     ; .. reverse mode
  ldx saved_font_mode   ; restore font
  stx font_mode
  lda font_attribute_table,x
  sta $0286   ; set colour
  jmp done_escape

; --- unknown ---
:   
; --- reset ESC mode ---
done_escape:
  lda #$00    ; reset escape_mode
  sta escape_mode
  rts 

; --- set Discard mode ---
set_discard_mode:
  lda #$f0    ; set esc mode $f0
  sta escape_mode
  rts


; -------------------------------------
; [ esc mode
;
; escape_mode = $ff
; -------------------------------------
  
long_escape_mode:
  tya         ; restore char
  ldy escape_buffer_length
  sta escape_buffer,y  ; store char
  iny
  sty escape_buffer_length   ; inc esc buffer  
  jsr test_if_letter   ; test letter
  bcs :+     ; process command
  rts

; --- process esc command ---
; A = last char
; Y = escape_buffer_length
; X counts processed command chars
:
  ldx #$00    ; first char 

; --- A --- crsr up       
  cmp #$41    ; A?
  bne @not_A
  jsr get_number_from_esc_seq  ; get argument
  lda escape_parameter    ; escape_parameter = 0...
  bne :+
  inc escape_parameter    ; .. means 1
:
  lda $d6     ; get crsr row        
  sec
  sbc escape_parameter    ; row = row - up
  cmp scroll_region_start     ; stop at top of ..
  bpl :+    ; ..scroll region
  lda scroll_region_start    
:
  tax         ; x is row
  ldy $d3     ; y is col
  jsr cursor_plot   ; set crsr
  jmp @end_escape_seq
  
; --- B --- crsr down
@not_A:
  cmp #$42    ; B?
  bne @not_B
  jsr get_number_from_esc_seq  ; get argument
  lda escape_parameter    ; escape_parameter = 0...
  bne :+
  inc escape_parameter    ; .. means 1        
:
  lda $d6     ; get crsr row        
  clc
  adc escape_parameter    ; row = row + down
  cmp scroll_region_end     ; outside scrregion?
  bcs :+    ; yes -> branch
  tax         ; x is row
  jmp @skip
:
 ldx scroll_region_end     ; x = row = scroll_region_end   
@skip:
  ldy $d3     ; y is col
  jsr cursor_plot   ; set crsr
  jmp @end_escape_seq

; --- C --- crsr right
@not_B:
  cmp #$43    ; C?
  bne @not_C
  jsr get_number_from_esc_seq  ; get argument        
  lda escape_parameter    ; escape_parameter = 0...
  bne :+
  inc escape_parameter    ; .. means 1
:
  lda $d3     ; get crsr col        
  clc
  adc escape_parameter    ; col = col + right
  cmp #$27    ; outside screen?
  bcs :+    ; yes -> branch
  tay
  jmp @skip2
:    
  ldy #$27    ; y=col=left margin
@skip2:
  ldx $d6     ; x is row
  jsr cursor_plot   ; set crsr
  jmp @end_escape_seq

; --- D --- crsr left
@not_C:
  cmp #$44    ; D?
  bne @not_D
  jsr get_number_from_esc_seq  ; get argument
  lda escape_parameter    ; escape_parameter = 0...
  bne :+
  inc escape_parameter    ; .. means 1        
:
  lda $d3     ; get crsr col        
  sec
  sbc escape_parameter    ; col = col - left
  bpl :+      ; stop at left..
  lda #$00    ; ..margin
:
  tay         ; y is col
  ldx $d6     ; x is row
  jsr cursor_plot   ; set crsr
  jmp @end_escape_seq

; --- m ---  font attributes
@not_D:
  cmp #$6d    ; m?
  bne @not_m
@next_font_attribute:
  jsr get_number_from_esc_seq
  pha         ; save nondigit char
  lda escape_parameter    ; parameter to A
  ; -- 0 --
  bne :+    ; 0?
  sta font_mode    ; set font = vanilla
  sta $c7     ; reverse off
  jmp @end_font_attribute    ; jmp next par
  ; -- 1 -- bold
:
  cmp #$01
  bne :+
  lda font_mode    ; set bold
  ora #$01
  sta font_mode
  jmp @end_font_attribute    ; next char
  ; -- 4 -- underline
:
  cmp #$04
  bne :+
  lda font_mode    ; set u_line
  ora #$02
  sta font_mode
  jmp @end_font_attribute    ; next char
  ; -- 5 -- blink
: 
  cmp #$05
  bne :+
  lda font_mode    ; set blink
  ora #$04
  sta font_mode
  jmp @end_font_attribute    ; next char
  ; -- 7 -- reverse
:
  cmp #$07
  bne :+
  lda #$01    ; set revers
  sta $c7
  jmp @end_font_attribute    ; next char
:
  ; -- 30 - 37 --
  cmp #38     ; >= 38?
  bcs @end_font_attribute
  cmp #30     ; < 30?
  bcc @end_font_attribute
  sbc #30     ; pointer for table
  sta direct_colour
  lda #$80    ; set direct colour
  sta font_mode
  
@end_font_attribute:  ; -- next char --
  pla         ; get nondigit char
  cmp #$3b    ; is semicolon?
  beq @next_font_attribute    ; then next cahr
  ; -- set colour --
  lda font_mode    ; 
  bmi :+    ; bit 7->direct col
  tax         ; font to colour
  lda font_attribute_table,x
  sta $0286   ; set colour
  jmp @end_escape_seq
:
  ; -- set direct colour --
  ldx direct_colour ; colour maping
  lda direct_colour_table,x
  sta $0286   ; set colour
  jmp @end_escape_seq

; --- K --- erase line
@not_m:
  cmp #$4b      ; K?
  bne @not_K
  jsr get_number_from_esc_seq    ; get parameter
  lda escape_parameter      ; in A
  ; -- 0 -- crsr to end of line
  bne :+
  jsr erase_to_end_of_line    ; erase end line
  jmp @end_escape_seq
  ; -- 1 -- begin to crsr
:
  cmp #$01
  bne :+
  jsr erase_line_to_cursor    ; erase beg line
  jmp @end_escape_seq
  ; -- 2 -- whole line
:
  cmp #$02
  bne :+      ; par undefined 
  ldx $d6       ; line in X
  jsr erase_line_by_number      ; erase line
  sta $ce       ; del char ..
                ; ..under crsr
:
  jmp @end_escape_seq        
  
; --- f --- same as H
@not_K:
  cmp #$66
  bne @not_f
  jmp @set_cursor_position      ; same as H

; --- H --- cursor position
@not_f:
  cmp #$48
  bne @not_H
@set_cursor_position:
  cpy #$01    ; no par means home
  bne :+
  ; -- home --
  ldx #$00
  ldy #$00
  jsr cursor_plot   ; set crsr
  jmp @end_escape_seq
  ; -- row, col --
:
  jsr get_number_from_esc_seq
  cmp #$3b    ; is ;?
  bne @end_set_cursor_position    ; no -> error
  ; -- prepare row --
  ldy escape_parameter    ; get row
  bne :+    ; 0 means 1
  iny
:       
  dey         ; line 1 -> line 0
  cpy #$19    ; >= 25?..
  bcs @end_set_cursor_position    ; ..error!
  sty temp_ptr_x ; save row
  ; -- prepare col
  jsr get_number_from_esc_seq
  ldy escape_parameter    ; get col
  bne :+    ; 0 means 1
  iny
:
  dey         ; line 1 -> line 0        
  cpy #$28    ; >= 40?..
  bcs @end_set_cursor_position    ; ..error!        
  ldx temp_ptr_x ; restore row to X
  jsr cursor_plot   ; set crsr
@end_set_cursor_position:
  jmp @end_escape_seq
           

; --- J --- erase screen
@not_H:
  cmp #$4a      ;J?
  bne @not_J
  jsr get_number_from_esc_seq    ; get parameter
  lda escape_parameter      ; in A
  ; -- 0 -- crsr to end
  bne @not_cursor_to_end
  jsr erase_to_end_of_line    ; del rest of line
  ldx $d6       ; get crsr line
@erase_next_line:
  inx           ; next line
  cpx #$19      ; line 25?
  bcs @end_escape_seq     ; then end
  txa
  pha           ; save X
  jsr erase_line_by_number      ; erase line
  pla
  tax           ; restore X
  jmp @erase_next_line      ; next line
  ; -- 1 -- beg of screen to crsr
@not_cursor_to_end:
  cmp #$01
  bne @not_start_to_cursor
  jsr erase_line_to_cursor    ; del start of ln
  ldx $d6       ; get crsr line
:
  dex           ; previous line
  bmi @end_escape_seq     ; neg line -> end
  txa
  pha           ; save X
  jsr erase_line_by_number      ; erase line
  pla
  tax           ; restore X
  jmp :-
  ; -- 2 -- del screen
@not_start_to_cursor:
  cmp #$02      ; unknown?
  bne @end_escape_seq     ; then ingnore
  ldx #$18      ; start at ln 24        
:
  txa
  pha           ; save X
  jsr erase_line_by_number      ; erase line
  pla
  tax           ; restore X
  dex           ; previous line
  bpl :-
  jmp @end_escape_seq


; --- r ---  set scroll region                 
@not_J:
  cmp #$72    ; r?
  bne @not_r
  ; -- prepare top --
  jsr get_number_from_esc_seq
  cmp #$3b    ; is ;?
  bne @error_in_escape_seq   ; no -> error
  ldy escape_parameter    ; get top
  dey         ; line 1 -> line 0
  cpy #$19    ; >=25?..
  bcs @error_in_escape_seq   ; ..error!
  sty temp_ptr_x ; save top      
  ; -- prepare bottom --
  jsr get_number_from_esc_seq
  ldy escape_parameter    ; get bottom
  dey         ; line 1 -> line 0
  cpy #$19    ; >=25?..
  bcs @error_in_escape_seq   ; ..error! 
  sty temp_ptr_y ; save bottom       
  ; -- validate lines --
  lda temp_ptr_x ; restore top
  cmp temp_ptr_y ; >= bottom?..
  bcs @error_in_escape_seq   ; ..error!
  sta scroll_region_start     ; top -> SRStart
  sty scroll_region_end     ; bottom -> SREnd
  ; -- home crsr
  ldx #$00
  ldy #$00
  jsr cursor_plot
@error_in_escape_seq:
  jmp @end_escape_seq        
        

@not_r:
; --- unknown ---
@end_escape_seq:
  lda #$00
  sta escape_buffer_length   ; reset esc buffer
  sta escape_mode   ; reset esc mode
  rts



; -------------------------------------
; Test letter
;
; char in A
; returns carry = 1 for A = letter
; -------------------------------------
test_if_letter:
  cmp #$41    ; smaller then A?
  bcs :+     ; no -> go on
  rts         ; return no letter
:
  cmp #$5b    ; smaller then Z+1?
  bcs :+     ; no -> go on
  sec         ; return letter
  rts
:  
  cmp #$61    ; smaller then a?
  bcs :+     ; no -> go on
  rts         ; return no letter
:  
  cmp #$7b    ; smaller then z+1?        
  bcs :+     ; no -> go on
  sec         ; return letter
  rts
:
  clc         ; return no letter
  rts        
        


; -------------------------------------
; test digit
;
; char in A
; returns carry = 1 for A = digit
; -------------------------------------

test_if_digit:
  cmp #$30    ; smaller then 0?
  bcs :+     ; no -> go on
  rts         ; return no digit
:
  cmp #$3a    ; smaller then 9+1?
  bcs :+     ; no -> go on
  sec         ; return digit
  rts
:
  clc         ; return no digit
  rts


; -------------------------------------
; get decimal number from esc sequence
;
; esc sequence in escape_buffer
; first index to process in X
; returns: number escape_parameter
;          first non digit char in  A
; -------------------------------------
get_number_from_esc_seq:
  lda #$00    ; assume $00
  sta escape_parameter
@next_digit:
  lda escape_buffer,x  ; get next char
  inx
  jsr test_if_digit   ; digit?
  bcc @done     ; no -> return
  sbc #$30    ; ascii to #
  pha         ; save digit
  ; old value * 10
  ; 10a = ( 4a + a ) * 2
  lda escape_parameter
  asl         
  asl         ; ( 4a
  clc
  adc escape_parameter    ; + a )
  asl         ; *2 
  sta escape_parameter    ; = 10a
  ; add new digit
  pla         ; resore new digit
  clc
  adc escape_parameter
  sta escape_parameter
  jmp @next_digit     ; next char        
@done:
  rts        


        
; *************************************
; *
; * outgoing data
; *
; *************************************
; -------------------------------------
; given a single char (read from keyboard)
; work out what data should be sent to the remote host.
; input:
; A = keypress
; output:
; Y=0 - no data to be sent (i.e. ignore keypress)
; Y=1 - A contains single byte to send
; Y=2 - AX points to null terminated string to send
; -------------------------------------

;Y=0 nothing to send
;Y=1 A = char to send
;Y=2 AX=pointer to asciiz string to send

vt100_transform_outbound_char: 
  tay
  lda petscii_to_ascii,y   ; PETSCII to ASCII
  bne :+
  ldy #0  ; ignore key
  rts
:                
  cmp #$ff
  beq output_string
  cmp #$fe
  beq command_key  ; command key
  ;default - send (possibly transformed) single char 
  ldy #1      ;means A contains single byte to send
@done:
rts



; -------------------------------------
; create an ansi control sequence
; -------------------------------------


output_string:
  tya         ; restore original key

; --- crsr U ---
  cmp #$91    ; test crsr U
  bne @not_U
  ldax  #ansi_cursor_up
  ldy   #2
  rts
; --- crsr L ---
@not_U:      
  cmp #$9d    ; test crsr L
  bne @not_L
  ldax #ansi_cursor_left
  ldy #2
  rts
@not_L:
  cmp #$0d  ;test CR
  bne @not_CR
  ldax #crlf
  ldy #2
  rts

@not_CR:
  ldy #0  ;must be some kind of error 
  rts


; -------------------------------------
; keypress was a command key
; -------------------------------------

command_key:  
        tya         ; restore character

; --- crsr R ---
; ---   ^]   ---
; both events send $1d
  cmp #$1d
  bne @not_crsr_R
  lda #$04    ; test control Key
  bit $028d
  beq @cursor_right   ; not pressed
  ; control ] is pressed
  tya         ; send ^]
  ldy #1
  rts

; crsr R 
@cursor_right:
  ldax #ansi_cursor_right
  ldy #2
  rts

; --- crsr D ---
; ---   ^Q   ---
; both events send char $11
@not_crsr_R:
  cmp #$11    ;^Q / crsr down
  bne @not_crsr_D
  lda #$04    ; test control Key
  bit $028d
  beq @cursor_down   ; not pressed
  ; control Q is pressed
  tya         ; send ^Q
  ldy #1
  rts
        
  ; crsr down is pressed        
@cursor_down:
  ldax #ansi_cursor_down
  ldy #2
  rts

; --- HOME key ---
; ---    ^S    ---
; both events send char $13
@not_crsr_D:
  cmp #$13    ;^S / HOME
  bne @not_home
  lda #$04    ; test control Key
  bit $028d
  beq @home  ; not pressed
  ; control S is pressed
  tya         ; send ^S
  ldy #1
  rts

@home: 
  lda #$09 ; send TAB
  ldy #1
  rts

; --- DEL key ---
; ---    ^T    ---
; both events send char $14
@not_home:
  cmp #$14    ;^T / DEL
  bne @not_del 
  lda #$04    ; test control Key
  bit $028d
  beq @del   ; not pressed
  ; control T is pressed
  tya         ; send ^T
  ldy #1
  rts
  
  ; send DEL
@del:
  lda #$08
  ldy #1
  rts


; --- unknown C=-Key ---
@not_del:
      ldy #0 ;means don't send anything
      rts

; *************************************
; *
; * screen handling
; *
; *************************************

; --- these variables become updated ---
;     on crsr movement.
;
; $d1 $d2  start of screen line
; $d3      crsr column
; $d6      crsr row
; $f3 $f4  start of colour line
; $0286    colour

; --- these variables become updated ---
;     on crsr switching.
;
; $cc    crsr flag, 0 = on
; $cd    crsr blink counter
; $ce    char under crsr
; $cf    crsr blink phase, 0 normal
; $0287  colour under crsr



; -------------------------------------
; switch curser off and restore char.
; this has to be done before every crsr
; movement.
; After movement there has to be a jump
; to cursor_on.
; -------------------------------------
cursor_off:
  pha         ; save registers
  tya
  pha             

  ldy #$01    ; crsr of
  sty $cc        
  lda $cf     ; crsr revers?
  beq :+     ; no -> return
  dey         ; set normal phase
  sty $cf        
  ldy $d3     ; get column
  lda $ce     ; restore char
  sta ($d1),y
  lda $0287   ; restore colour
  sta ($f3),y

:
  pla         ; restore registers
  tay
  pla
  rts

; -------------------------------------
; opposite of cursor_off
; -------------------------------------

cursor_on:
  pha
  tya
  pha
          
  ldy $d3     ; get column
  lda ($d1),y ; save chr
  sta $ce 
  eor #$80    ; reverse char
  sta ($d1),y        
  lda ($f3),y ; save colour
  sta $0287
  lda $0286   ; set crsr colour
  sta ($f3),y
  inc $cf     ; set reverse phase
  lda #$14    ; set crsr counter..
  sta $cd     ; ..to max
  lda #$00    ; cursor on
  sta $cc 
  
  pla
  tay
  pla
  rts



; -------------------------------------
; moves the crsr to column Y
; and line X
; the crsr ist turned off during 
; operation
; destroys all registers
; -------------------------------------
cursor_plot:
  jsr cursor_off
  
  stx $d6     ; set row
  sty $d3     ; set col
  jsr set_line_vectors
  ldx temp_ptr_x ; set screen line
  ldy temp_ptr_x+1
  stx $d1
  sty $d2
  ldx temp_ptr_y ; set color line
  ldy temp_ptr_y+1
  stx $f3
  sty $f4
  
  jsr cursor_on        
  rts
        

; -------------------------------------
; Print char in A to screen
; being aware of the crsr state
; -------------------------------------

print_to_screen:
  jsr cursor_off
  jsr plot_char
  jsr cursor_on
  rts

; -------------------------------------
; print char to screen
; char = $ff means no output
; chr in A
; X and Y unaffected
; -------------------------------------

plot_char:
  sta temp_ptr_x ; save char
  txa         ; save registers
  pha
  tya
  pha
  lda temp_ptr_x ; restore char

; PETSCII to ScreenCode (SC)
; --- $c0-$ff ---   - illegal -
  cmp #$c0
  bcc :+
  jmp end_plot_char   ; no output
; --- $a0-$bf ---   C=(latin-1) chars
:       
  cmp #$a0
  bcc :+
  sbc #$40    ; SC = PET - $40
  jmp @check_for_reverse
; --- $80-$9f ---   - illegal -
:       
  cmp #$80
  bcc :+
  jmp end_plot_char   ; no output
; --- $60-$7f ---  kapital letters        
:
  cmp #$60
  bcc :+
  sbc #$20    ; SC = PET - $20
  jmp @check_for_reverse
; --- $40-$5f ---  small letters
:
  cmp #$40
  bcc :+        
  sbc #$40    ; SC = PET - $40
  jmp @check_for_reverse
; --- $20-$3f ---  interpunction
:
  cmp #$20
  bcc :+
  jmp @check_for_reverse   ; SC = PET
; --- $00-$1f ---  - illegal -
:
  jmp end_plot_char   ; no output

; --- handle reverse mode---
@check_for_reverse:
  ldx $c7     ; reverse mode?
  beq @put_char
  ora #$80    ; reverse char

; --- put char to screen ---
@put_char:
  ldy $d3     ; get crsr col
  cpy #$28    ;col = 40
  bcc @no_line_wrap
              ;the only way we end up trying to write to column 40 should
              ;be if we skipped the normal line wrap after writing to col 39
              ;because we are at the end of the scroll region
              ;that means we should do a scroll up and then write this char at col 0
  pha
  jsr scroll_up_scrollregion
  pla
  ldy #$00    ; begin of line
  sty $d3
@no_line_wrap:  
  sta ($d1),y ; char to screen
  lda $0286   ; get colour
  sta ($f3),y ; set colour
  
; --- move on crsr ---
  
  ldx $d6     ; get crsr row
  cpx scroll_region_end     ; end of scroll reg?  
  beq @dont_scroll_yet     ; we don't want to trigger a scroll of the whole screen unless
                                    ; we are actually writing a char. we shouldn't scroll just when
                                    ; writing to the bottom right hand screen (else e.g. the title bar 
                                    ; in 'nano' gets pushed off the top of the screen.
                                    ;
  cpy #$27    ; col = 39?
  beq move_to_next_line   ; yes -> new line
@dont_scroll_yet:  
  iny         ; move on
  sty $d3
  
end_plot_char:
  pla         ; restore registers
  tay
  pla
  tax
  rts
        
; -------------------------------------
; subtask of plot_char
; ends at end_plot_char
; -------------------------------------
move_to_next_line:
  ldx $d6     ; get crsr row
  cpx scroll_region_end     ; end of scroll reg?
  beq @scroll_up     ; yes -> branche
  cpx #$18    ; line 24?
  beq end_plot_char   ; yes -> crsr stays
; --- normal wrap ---
  inx         ; increase line
  stx $d6
  ldy #$00    ; begin of line
  sty $d3
  jsr set_line_vectors
  ldx temp_ptr_x ; set screen line
  ldy temp_ptr_x+1
  stx $d1
  sty $d2
  ldx temp_ptr_y ; set colour line
  ldy temp_ptr_y+1
  stx $f3
  sty $f4        
  jmp end_plot_char
; --- scroll up ---        
@scroll_up:
  jsr scroll_up_scrollregion
  ldy #$00    ; begin of line
  sty $d3
  jmp end_plot_char
  


scroll_up_scrollregion:
  ldx scroll_region_start     ; get first line
@scroll_one_line:
  ; -- new line: --
  ; -- temp_ptr_z and temp_ptr_w --
  jsr set_line_vectors
  lda temp_ptr_x ; screen line
  ldy temp_ptr_x+1
  sta temp_ptr_z
  sty temp_ptr_z+1
  lda temp_ptr_y ; colour line
  ldy temp_ptr_y+1
  sta temp_ptr_w
  sty temp_ptr_w+1
  ; -- old line: --
  ; -- temp_ptr_x and temp_ptr_y
  inx             ; old line
  jsr set_line_vectors
  ; -- copy chars and colours --
  ldy #$27        ; col 39
@scroll_one_char:
  lda (temp_ptr_x),y ; copy char
  sta (temp_ptr_z),y
  lda (temp_ptr_y),y ; copy colour
  sta (temp_ptr_w),y
  dey
  bpl @scroll_one_char
  cpx scroll_region_end         ; last line?
  bne @scroll_one_line         ; no -> go on
  jsr erase_line_by_vector       ; del last line
  
  rts
  

scroll_down_scrollregion:
  ldx scroll_region_end     ; get last line
@scroll_one_line:
  jsr set_line_vectors
  lda temp_ptr_x ; screen line
  ldy temp_ptr_x+1
  sta temp_ptr_z
  sty temp_ptr_z+1
  lda temp_ptr_y ; colour line
  ldy temp_ptr_y+1
  sta temp_ptr_w
  sty temp_ptr_w+1
  ; -- old line: --
  ; -- temp_ptr_x and temp_ptr_y
  dex             ; old line
  jsr set_line_vectors
  ; -- copy chars ond colours --
  ldy #$27        ; col 39
@scroll_one_char:
  lda (temp_ptr_x),y ; copy char
  sta (temp_ptr_z),y
  lda (temp_ptr_y),y ; copy colour
  sta (temp_ptr_w),y
  dey
  bpl @scroll_one_char
  cpx scroll_region_start         ; first line?
  bne @scroll_one_line         ; no -> go on
  jsr erase_line_by_vector       ; del first line
  
  rts


; -------------------------------------
; print string to screen
; string: chars, terminated by $00
; start lo in x
; start hi in y
; affects A
; takes care of crsr
; the string must be smaller 
;   than 255 chrs
; -------------------------------------


plot_string:
  stx print_ptr   ; store start vector
  sty print_ptr+1
  jsr cursor_off        
  ldy #$00
@next_char:
  lda (print_ptr),y
  beq @end_string      ; $00 terminates string
  jsr plot_char        
  iny
  jmp @next_char

@end_string:
  jsr cursor_on
  rts



; -------------------------------------
; delete screen line 
; (Erase Line)
;
; line number in X
;
; erase_line_by_vector needs line vectors in temp_ptr_x 
;                         and temp_ptr_y
;
; destroys all registers
; returns $20 (space) in A
; -------------------------------------

erase_line_by_number:
  jsr set_line_vectors ; line start in temp_ptr_x
          ; col  start in temp_ptr_y

; erase chars
erase_line_by_vector:
  ldy #$27      ; col 39
  lda #$20      ; load space
:
  sta (temp_ptr_x),y ; clear char
  dey 
  bpl :-

; set colour
  ldy #$27      ; col 39
  lda #charmode_vanilla      ; load vanilla
:  
  sta (temp_ptr_y),y ; clear char
  dey 
  bpl :-
  
  rts
        


; -------------------------------------
; delete screen line from crsr to end
; (Erase End of Line)
; destroys all registers
; -------------------------------------

erase_to_end_of_line:
  jsr cursor_off
; erase chars
  ldy $d3       ; get crsr col
  lda #$20      ; load space
:
  sta ($d1),y   ; clear char
  iny
  cpy #$28      ; pos 40?
  bne :-      ; next char
  sta $ce       ; del char ..
                ; ..under crsr
; set colour
  ldy $d3       ; get crsr col
  lda #charmode_vanilla      ; load vanilla
:
  sta ($f3),y   ; set colour
  iny
  cpy #$28      ; pos 40?
  bne :-      ; next char        
  jsr cursor_on
  rts

; -------------------------------------
; delete screen line up to crsr
; (Erase Begin of Line)
; destroys all registers
; -------------------------------------
erase_line_to_cursor:
; erase chars
  ldy $d3       ; get crsr col
  lda #$20      ; load space
:  
  sta ($d1),y   ; clear char
  dey
  bpl :-      ; pos>=0 -> next
  sta $ce       ; del char ..
                ; ..under crsr
; set colour                      
  ldy $d3       ; get crsr col
  lda #charmode_vanilla      ; load vanilla
:
  sta ($f3),y   ; clear char
  dey
  bpl :-        ; pos>=0 -> next        
  rts


; -------------------------------------
; set line vectors
;
; line no in X
; destroys A and Y
;
; sets start of screen line in temp_ptr_x
; sets start of colour line in temp_ptr_y
; -------------------------------------

set_line_vectors:
  lda $ecf0,x   ; get lo byte
  sta temp_ptr_x
  sta temp_ptr_y
  ; determin hi byte
  ldy #$04      ; hi byte
  cpx #$07      ; line < 7?
  bcc @got_line_vector
  iny           
  cpx #$0d      ; line < 13?
  bcc @got_line_vector
  iny
  cpx #$14      ; line < 20?
  bcc @got_line_vector
  iny           ; line 20-24
@got_line_vector:
  sty temp_ptr_x+1
  tya
  clc           ; colour RAM =
  adc #$d4      ; video RAM + d4
  sta temp_ptr_y+1        
  rts



; -------------------------------------
; init routines
;
; -------------------------------------


initialise_screen:

 ;--- set background ---
  lda #text_background_colour
  sta $d021
; --- disable Shift C= ---
  lda #$80
  sta $0291        
; --- erase screen ---
  ldx #$18      ; start at ln 24        
@erase_one_line:
  txa
  pha           ; save X
  jsr erase_line_by_number      ; erase line
  pla
  tax           ; restore X
  dex           ; previous line
  bpl @erase_one_line

  lda #charmode_vanilla     ; load vanilla
  sta $0286
; --- crsr on ---
  jsr cursor_off
  jsr cursor_on
; --- put crsr ---
  jsr do_cr
  jsr do_line_feed
  jsr do_line_feed
  
  rts
  


initialise_variables:
  lda #$00
  sta escape_mode
  sta escape_buffer_length
  sta scroll_region_start
  sta font_mode
  sta saved_font_mode
  sta saved_reverse_mode
  sta saved_row
  sta saved_column
  
  lda #$18    ; last line
  sta scroll_region_end     ; = 24
  
  rts


reverse_font_table = font_table + $0400
initialise_font:  
  sei
  ldx #<ROM_FONT ; font_mode in temp_ptr_z
  ldy #>ROM_FONT
  stx temp_ptr_z
  sty temp_ptr_z+1
  ldx #<font_table    
  ldy #>font_table
  stx temp_ptr_y
  sty temp_ptr_y+1
  ldx #<reverse_font_table 
  ldy #>reverse_font_table
  stx temp_ptr_x
  sty temp_ptr_x+1
  
; copy font        
  ldx #$04      ; copy 4 pages = 1KB
  ldy #$00      
:
  lda (temp_ptr_z),y
  sta (temp_ptr_y),y
  eor #$ff      ; reverse char
  sta (temp_ptr_x),y
  iny
  bne :-
  ; switch to next page
  inc temp_ptr_z+1
  inc temp_ptr_y+1
  inc temp_ptr_x+1
  dex
  bne :-
  
; enable font
  lda $d018
  and #$f1
  ora #$09
  sta $d018
  cli
  rts


.rodata
font_attribute_table:    ; bits mean blink, underline, bold
.byte charmode_vanilla, charmode_bold                           ; 000 001
.byte charmode_underline, charmode_underline_bold               ; 010 011
.byte charmode_blink, charmode_blink_bold                       ; 100 101
.byte charmode_blink_underline, charmode_blink_underline_bold   ; 110 111

direct_colour_table:
;ANSI 30   31 32 32   34 35 36 37 
;    blk   rd gr ye  blu mg cy wh
.byte  0, $0a, 5, 7, $0e, 4, 3, 1

ansi_cursor_up:     .byte esc, brace, $41, $00 ; esc [ A 
ansi_cursor_down:   .byte esc, brace, $42, $00 ; esc [ B
ansi_cursor_right:  .byte esc, brace, $43, $00 ; esc [ C 
ansi_cursor_left:   .byte esc, brace, $44, $00 ; esc [ D 
crlf:  .byte $0d,$0a,0

; -------------------------------------
; table ASCII  to PETSCII 
;
; these characters cat be printed
;
; pet=$00 means ignore the char
; pet=$01 means do something complicated
; -------------------------------------
ascii_to_petscii:
  .byte $00   ; $00
  .byte $00   ; $01
  .byte $00   ; $02
  .byte $00   ; $03
  .byte $00   ; $04
  .byte $00   ; $05
  .byte $00   ; $06
  .byte $01   ; $07 BEL
  .byte $01   ; $08 BS/DEL
  .byte $01   ; $09 TAB
  .byte $01   ; $0a LF
  .byte $00   ; $0b
  .byte $00   ; $0c
  .byte $01   ; $0d CR
  .byte $00   ; $0e
  .byte $00   ; $0f
  .byte $00   ; $10
  .byte $00   ; $11
  .byte $00   ; $12
  .byte $00   ; $13 
  .byte $00   ; $14
  .byte $00   ; $15
  .byte $00   ; $16
  .byte $00   ; $17
  .byte $00   ; $18
  .byte $00   ; $19
  .byte $00   ; $1a
  .byte $01   ; $1b ESC
  .byte $00   ; $1c
  .byte $00   ; $1d
  .byte $00   ; $1e
  .byte $00   ; $1f
  .byte $20   ; $20  1:1
  .byte $21   ; $21  1:1
  .byte $22   ; $22  1:1
  .byte $23   ; $23  1:1
  .byte $24   ; $24  1:1
  .byte $25   ; $25  1:1
  .byte $26   ; $26  1:1
  .byte $27   ; $27  1:1
  .byte $28   ; $28  1:1
  .byte $29   ; $29  1:1
  .byte $2a   ; $2a  1:1
  .byte $2b   ; $2b  1:1
  .byte $2c   ; $2c  1:1
  .byte $2d   ; $2d  1:1
  .byte $2e   ; $2e  1:1
  .byte $2f   ; $2f  1:1
  .byte $30   ; $30  1:1
  .byte $31   ; $31  1:1
  .byte $32   ; $32  1:1
  .byte $33   ; $33  1:1
  .byte $34   ; $34  1:1
  .byte $35   ; $35  1:1
  .byte $36   ; $36  1:1
  .byte $37   ; $37  1:1
  .byte $38   ; $38  1:1
  .byte $39   ; $39  1:1
  .byte $3a   ; $3a  1:1
  .byte $3b   ; $3b  1:1
  .byte $3c   ; $3c  1:1
  .byte $3d   ; $3d  1:1
  .byte $3e   ; $3e  1:1
  .byte $3f   ; $3f  1:1
  .byte $40   ; $40  1:1
  .byte $61   ; $41 -----
  .byte $62   ; $42
  .byte $63   ; $43
  .byte $64   ; $44 capital
  .byte $65   ; $45
  .byte $66   ; $46
  .byte $67   ; $47
  .byte $68   ; $48
  .byte $69   ; $49
  .byte $6a   ; $4a
  .byte $6b   ; $4b
  .byte $6c   ; $4c
  .byte $6d   ; $4d letters
  .byte $6e   ; $4e
  .byte $6f   ; $4f
  .byte $70   ; $50
  .byte $71   ; $51
  .byte $72   ; $52
  .byte $73   ; $53
  .byte $74   ; $54
  .byte $75   ; $55
  .byte $76   ; $56
  .byte $77   ; $57
  .byte $78   ; $58
  .byte $79   ; $59
  .byte $7a   ; $5a -----
  .byte $5b   ; $5b  1:1
  .byte $5c   ; $5c  1:1
  .byte $5d   ; $5d  1:1
  .byte $5e   ; $5e  1:1
  .byte $5f   ; $5f  1:1
  .byte $60   ; $60  1:1
  .byte $41   ; $61 -----
  .byte $42   ; $62
  .byte $43   ; $63
  .byte $44   ; $64 small
  .byte $45   ; $65
  .byte $46   ; $66
  .byte $47   ; $67
  .byte $48   ; $68
  .byte $49   ; $69
  .byte $4a   ; $6a
  .byte $4b   ; $6b letters
  .byte $4c   ; $6c
  .byte $4d   ; $6d
  .byte $4e   ; $6e
  .byte $4f   ; $6f
  .byte $50   ; $70
  .byte $51   ; $71
  .byte $52   ; $72
  .byte $53   ; $73
  .byte $54   ; $74
  .byte $55   ; $75
  .byte $56   ; $76
  .byte $57   ; $77
  .byte $58   ; $78
  .byte $59   ; $79
  .byte $5a   ; $7a -----
  .byte $7b   ; $7b  1:1 {
  .byte $7c   ; $7c  1:1 |
  .byte $7d   ; $7d  1:1 }
  .byte $7e   ; $7e  1:1 ~
  .byte $00   ; $7f
  .byte $00   ; $80
  .byte $00   ; $81
  .byte $00   ; $82
  .byte $00   ; $83
  .byte $00   ; $84
  .byte $00   ; $85
  .byte $00   ; $86
  .byte $00   ; $87
  .byte $00   ; $88
  .byte $00   ; $89
  .byte $00   ; $8a
  .byte $00   ; $8b
  .byte $00   ; $8c
  .byte $00   ; $8d
  .byte $00   ; $8e
  .byte $00   ; $8f
  .byte $00   ; $90
  .byte $00   ; $91
  .byte $00   ; $92
  .byte $00   ; $93
  .byte $00   ; $94
  .byte $00   ; $95
  .byte $00   ; $96
  .byte $00   ; $97
  .byte $00   ; $98
  .byte $00   ; $99
  .byte $00   ; $9a
  .byte $00   ; $9b
  .byte $00   ; $9c
  .byte $00   ; $9d
  .byte $00   ; $9e
  .byte $00   ; $9f
  .byte $20   ; $a0
  .byte $7f   ; $a1
  .byte $7f   ; $a2
  .byte $bf   ; $a3
  .byte $be   ; $a4
  .byte $7f   ; $a5
  .byte $73   ; $a6
  .byte $b5   ; $a7
  .byte $53   ; $a8
  .byte $bb   ; $a9
  .byte $7f   ; $aa
  .byte $bc   ; $ab
  .byte $7f   ; $ac
  .byte $2d   ; $ad
  .byte $7f   ; $ae
  .byte $7f   ; $af
  .byte $ba   ; $b0
  .byte $b8   ; $b1
  .byte $b6   ; $b2
  .byte $b7   ; $b3
  .byte $7a   ; $b4
  .byte $b9   ; $b5
  .byte $7f   ; $b6
  .byte $7f   ; $b7
  .byte $5a   ; $b8
  .byte $7f   ; $b9
  .byte $7f   ; $ba
  .byte $bd   ; $bb
  .byte $b0   ; $bc
  .byte $b0   ; $bd
  .byte $79   ; $be
  .byte $7f   ; $bf
  .byte $a5   ; $c0
  .byte $61   ; $c1
  .byte $a4   ; $c2
  .byte $61   ; $c3
  .byte $a3   ; $c4
  .byte $a4   ; $c5
  .byte $7f   ; $c6
  .byte $63   ; $c7
  .byte $ad   ; $c8
  .byte $ab   ; $c9
  .byte $ac   ; $ca
  .byte $65   ; $cb
  .byte $69   ; $cc
  .byte $69   ; $cd
  .byte $69   ; $ce
  .byte $69   ; $cf
  .byte $64   ; $d0
  .byte $6e   ; $d1
  .byte $6f   ; $d2
  .byte $6f   ; $d3
  .byte $b1   ; $d4
  .byte $6f   ; $d5
  .byte $af   ; $d6
  .byte $7f   ; $d7
  .byte $6f   ; $d8
  .byte $75   ; $d9
  .byte $75   ; $da
  .byte $75   ; $db
  .byte $b3   ; $dc
  .byte $79   ; $dd
  .byte $7f   ; $de
  .byte $b4   ; $df
  .byte $a2   ; $e0
  .byte $41   ; $e1
  .byte $a1   ; $e2
  .byte $41   ; $e3
  .byte $a0   ; $e4
  .byte $a1   ; $e5
  .byte $7f   ; $e6
  .byte $a6   ; $e7
  .byte $aa   ; $e8
  .byte $a8   ; $e9
  .byte $a9   ; $ea
  .byte $a7   ; $eb
  .byte $49   ; $ec
  .byte $49   ; $ed
  .byte $49   ; $ee
  .byte $49   ; $ef
  .byte $7f   ; $f0
  .byte $4e   ; $f1
  .byte $4f   ; $f2
  .byte $4f   ; $f3
  .byte $b1   ; $f4
  .byte $4f   ; $f5
  .byte $ae   ; $f6
  .byte $7f   ; $f7
  .byte $4f   ; $f8
  .byte $55   ; $f9
  .byte $55   ; $fa
  .byte $55   ; $fb
  .byte $b2   ; $fc
  .byte $59   ; $fd
  .byte $7f   ; $fe
  .byte $59   ; $ff

; -------------------------------------
; table PETSCII  to ASCII 
;
; these characters can be typed with 
; the keyboard
;
; ascii = $00 means ignore key
; ascii = $ff menas send string
; ascii = $fe means do something 
;             complicated (command key)
; -------------------------------------
petscii_to_ascii:
  .byte $00   ; $00
  .byte $01   ; $01
  .byte $02   ; $02
  .byte $03   ; $03
  .byte $04   ; $04
  .byte $05   ; $05
  .byte $06   ; $06
  .byte $07   ; $07
  .byte $08   ; $08 DEL
  .byte $09   ; $09 TAB
  .byte $0a   ; $0a
  .byte $0b   ; $0b
  .byte $0c   ; $0c
  .byte $ff   ; $0d CR
  .byte $0e   ; $0e
  .byte $0f   ; $0f
  .byte $10   ; $10
  .byte $fe   ; $11 ^Q (crsr down)
  .byte $12   ; $12
  .byte $fe   ; $13 ^S TAB (HOME)
  .byte $fe   ; $14 ^T BS  (DEL)
  .byte $15   ; $15
  .byte $16   ; $16
  .byte $17   ; $17
  .byte $18   ; $18
  .byte $19   ; $19
  .byte $1a   ; $1a
  .byte $1b   ; $1b ESC
  .byte $1c   ; $1c
  .byte $fe   ; $1d ^](crsr right)
  .byte $1e   ; $1e
  .byte $1f   ; $1f
  .byte $20   ; $20 SPACE
  .byte $21   ; $21 !
  .byte $22   ; $22 "
  .byte $23   ; $23 #
  .byte $24   ; $24 $
  .byte $25   ; $25 %
  .byte $26   ; $26 &
  .byte $27   ; $27 '
  .byte $28   ; $28 (
  .byte $29   ; $29 )
  .byte $2a   ; $2a *
  .byte $2b   ; $2b +
  .byte $2c   ; $2c ,
  .byte $2d   ; $2d -
  .byte $2e   ; $2e .
  .byte $2f   ; $2f /
  .byte $30   ; $30 0
  .byte $31   ; $31 1
  .byte $32   ; $32 2
  .byte $33   ; $33 3
  .byte $34   ; $34 4
  .byte $35   ; $35 5
  .byte $36   ; $36 6
  .byte $37   ; $37 7
  .byte $38   ; $38 8
  .byte $39   ; $39 9
  .byte $3a   ; $3a :
  .byte $3b   ; $3b ;
  .byte $3c   ; $3c <
  .byte $3d   ; $3d =
  .byte $3e   ; $3e >
  .byte $3f   ; $3f ?
  .byte $40   ; $40 @
  .byte $61   ; $41 a
  .byte $62   ; $42 b
  .byte $63   ; $43 c
  .byte $64   ; $44 d
  .byte $65   ; $45 e
  .byte $66   ; $46 f
  .byte $67   ; $47 g
  .byte $68   ; $48 h
  .byte $69   ; $49 i
  .byte $6a   ; $4a j
  .byte $6b   ; $4b k
  .byte $6c   ; $4c l
  .byte $6d   ; $4d m
  .byte $6e   ; $4e n
  .byte $6f   ; $4f o
  .byte $70   ; $50 p
  .byte $71   ; $51 q
  .byte $72   ; $52 r
  .byte $73   ; $53 s
  .byte $74   ; $54 t
  .byte $75   ; $55 u
  .byte $76   ; $56 v
  .byte $77   ; $57 w
  .byte $78   ; $58 x
  .byte $79   ; $59 y
  .byte $7a   ; $5a z
  .byte $5b   ; $5b [
  .byte $5c   ; $5c \ (Pound)
  .byte $5d   ; $5d ]
  .byte $5e   ; $5e ^
  .byte $1b   ; $5f ESC ( <- )
  .byte $00   ; $60 
  .byte $41   ; $61 A
  .byte $42   ; $62 B
  .byte $43   ; $63 C
  .byte $44   ; $64 D
  .byte $45   ; $65 E
  .byte $46   ; $66 F
  .byte $47   ; $67 G
  .byte $48   ; $68 H
  .byte $49   ; $69 I
  .byte $4a   ; $6a J
  .byte $4b   ; $6b K
  .byte $4c   ; $6c L
  .byte $4d   ; $6d M
  .byte $4e   ; $6e N
  .byte $4f   ; $6f O
  .byte $50   ; $70 P
  .byte $51   ; $71 Q
  .byte $52   ; $72 R
  .byte $53   ; $73 S
  .byte $54   ; $74 T
  .byte $55   ; $75 U
  .byte $56   ; $76 V
  .byte $57   ; $77 W
  .byte $58   ; $78 X
  .byte $59   ; $79 Y
  .byte $5a   ; $7a Z
  .byte $00   ; $7b
  .byte $00   ; $7c
  .byte $00   ; $7d
  .byte $00   ; $7e
  .byte $00   ; $7f
  .byte $00   ; $80
  .byte $00   ; $81
  .byte $00   ; $82
  .byte $00   ; $83
  .byte $00   ; $84
  .byte $00   ; $85 (f1)
  .byte $00   ; $86 (f3)
  .byte $00   ; $87 (f5)
  .byte $00   ; $88 (f7)
  .byte $00   ; $89 (f2)
  .byte $00   ; $8a (f4)
  .byte $00   ; $8b (f6)
  .byte $00   ; $8c (f8)
  .byte $00   ; $8d (Shift RET)
  .byte $00   ; $8e
  .byte $00   ; $8f
  .byte $00   ; $90
  .byte $ff   ; $91 (crsr up)
  .byte $00   ; $92
  .byte $00   ; $93 (Shift Clr/Home)
  .byte $7f   ; $94 DEL (Shift Ins/Del)
  .byte $00   ; $95
  .byte $00   ; $96
  .byte $00   ; $97
  .byte $00   ; $98
  .byte $00   ; $99
  .byte $00   ; $9a
  .byte $00   ; $9b
  .byte $00   ; $9c
  .byte $ff   ; $9d (crsr left)
  .byte $00   ; $9e
  .byte $00   ; $9f
  .byte $00   ; $a0 (Shift Space)
  .byte $00   ; $a1
  .byte $00   ; $a2
  .byte $00   ; $a3
  .byte $00   ; $a4
  .byte $00   ; $a5
  .byte $00   ; $a6
  .byte $00   ; $a7
  .byte $00   ; $a8
  .byte $7c   ; $a9 | (Shift Pound)
  .byte $00   ; $aa
  .byte $00   ; $ab
  .byte $fe   ; $ac  C= D
  .byte $00   ; $ad
  .byte $fe   ; $ae  C= S
  .byte $00   ; $af
  .byte $fe   ; $b0  C= A
  .byte $00   ; $b1
  .byte $fe   ; $b2  C= R
  .byte $00   ; $b3
  .byte $00   ; $b4
  .byte $00   ; $b5
  .byte $fe   ; $b6  C= L
  .byte $00   ; $b7
  .byte $00   ; $b8
  .byte $00   ; $b9
  .byte $60   ; $ba ` ( Shift @ )
  .byte $00   ; $bb
  .byte $fe   ; $bc  C= C
  .byte $00   ; $bd
  .byte $00   ; $be
  .byte $fe   ; $bf  C= B
  .byte $5f   ; $c0 _ ( Shift * )
  .byte $41   ; $c1 -----
  .byte $42   ; $c2
  .byte $43   ; $c3 capital
  .byte $44   ; $c4
  .byte $45   ; $c5 letters
  .byte $46   ; $c6
  .byte $47   ; $c7 generate
  .byte $48   ; $c8 
  .byte $49   ; $c9 these 
  .byte $4a   ; $ca
  .byte $4b   ; $cb codes
  .byte $4c   ; $cc
  .byte $4d   ; $cd
  .byte $4e   ; $ce
  .byte $4f   ; $cf
  .byte $50   ; $d0
  .byte $51   ; $d1
  .byte $52   ; $d2
  .byte $53   ; $d3
  .byte $54   ; $d4
  .byte $55   ; $d5
  .byte $56   ; $d6
  .byte $57   ; $d7
  .byte $58   ; $d8
  .byte $59   ; $d9
  .byte $5a   ; $da -----
  .byte $7b   ; $db { ( Shift + )
  .byte $00   ; $dc   ( C= -   )
  .byte $7d   ; $dd } ( Shift - )
  .byte $7e   ; $de ~ ( Pi )
  .byte $00   ; $df
  .byte $00   ; $e0
  .byte $00   ; $e1
  .byte $00   ; $e2
  .byte $00   ; $e3
  .byte $00   ; $e4
  .byte $00   ; $e5
  .byte $00   ; $e6
  .byte $00   ; $e7
  .byte $00   ; $e8
  .byte $00   ; $e9
  .byte $00   ; $ea 
  .byte $00   ; $eb
  .byte $00   ; $ec
  .byte $00   ; $ed
  .byte $00   ; $ee
  .byte $00   ; $ef
  .byte $00   ; $f0
  .byte $00   ; $f1
  .byte $00   ; $f2
  .byte $00   ; $f3
  .byte $00   ; $f4
  .byte $00   ; $f5
  .byte $00   ; $f6
  .byte $00   ; $f7
  .byte $00   ; $f8
  .byte $00   ; $f9
  .byte $00   ; $fa
  .byte $00   ; $fb
  .byte $00   ; $fc
  .byte $00   ; $fd
  .byte $00   ; $fe
  .byte $00   ; $ff

ROM_FONT:
.incbin "../inc/vt100_font.bin"

;-- LICENSE FOR c64_vt100.s --
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
; The Initial Developer of the Original Code is Lars Stollenwerk.
; 
; Portions created by the Initial Developer are Copyright (C) 2003
; Lars Stollenwerk. All Rights Reserved.  
;
;Contributor(s): Jonno Downes
; -- LICENSE END --
