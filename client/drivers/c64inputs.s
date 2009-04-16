.export get_key  
.export get_filtered_input
.export filter_text
.export filter_ip
.export filter_dns
.export check_for_abort_key

.importzp copy_src

.include "../inc/common.i"
.code

allowed_ptr=copy_src ;reuse zero page

;use C64 Kernel ROM function to read a key
;inputs: none
;outputs: A contains ASCII value of key just pressed
get_key:
  jsr $ffe4
  beq get_key
  rts

;check whether the RUN/STOP key is being pressed
;inputs: none
;outputs: sec if RUN/STOP pressed, clear otherwise
check_for_abort_key:
  lda $cb ;current key pressed
  cmp #$3F
  bne @not_abort
@flush_loop:
  jsr $ffe4
  bne @flush_loop
  sec
  rts
@not_abort:
  clc
  rts

;cribbed from http://codebase64.org/doku.php?id=base:robust_string_input
;======================================================================
;Input a string and store it in GOTINPUT, terminated with a null byte.
;x:a is a pointer to the allowed list of characters, null-terminated.
;max # of chars in y returns num of chars entered in y.
;======================================================================


; Main entry
get_filtered_input:
  sty MAXCHARS
  stax allowed_ptr

  ;Zero characters received.
  lda #$00
  sta INPUT_Y

;Wait for a character.
INPUT_GET:
  jsr get_key
  sta LASTCHAR

  cmp #$14               ;Delete
  beq DELETE

  cmp #$0d               ;Return
  beq INPUT_DONE

  ;Check the allowed list of characters.
  ldy #$00
CHECKALLOWED:
  lda (allowed_ptr),y           ;Overwritten
  beq INPUT_GET         ;Reached end of list (0)

  cmp LASTCHAR
  beq INPUTOK           ;Match found

  ;Not end or match, keep checking
  iny
  jmp CHECKALLOWED

INPUTOK:
  lda LASTCHAR          ;Get the char back
  ldy INPUT_Y
  sta GOTINPUT,y        ;Add it to string
  jsr $ffd2             ;Print it

  inc INPUT_Y           ;Next character

  ;End reached?
  lda INPUT_Y
  cmp MAXCHARS
  beq INPUT_DONE

  ;Not yet.
  jmp INPUT_GET

INPUT_DONE:
   ldy INPUT_Y
   beq  no_input
   lda #$00
   sta GOTINPUT,y   ;Zero-terminate
   clc
   ldax #GOTINPUT
   rts
no_input:
   sec
   rts
; Delete last character.
DELETE:
  ;First, check if we're at the beginning.  If so, just exit.
  lda INPUT_Y
  bne DELETE_OK
  jmp INPUT_GET

  ;At least one character entered.
DELETE_OK:
  ;Move pointer back.
  dec INPUT_Y

  ;Store a zero over top of last character, just in case no other characters are entered.
  ldy INPUT_Y
  lda #$00
  sta GOTINPUT,y

  ;Print the delete char
  lda #$14
  jsr $ffd2

  ;Wait for next char
  jmp INPUT_GET


;=================================================
;Some example filters
;=================================================

filter_text:
  .byte ",+!#$%&'()* "
filter_dns:
.byte " -ABCDEFGHIJKLMNOPQRSTUVWXYZ"
filter_ip:
.byte "1234567890.",0

;=================================================
.bss
MAXCHARS: .res 1
LASTCHAR: .res 1
INPUT_Y: .res 1  
GOTINPUT: .res 40

