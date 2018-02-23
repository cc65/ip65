.export get_filtered_input
.export filter_text
.export filter_ip
.export filter_dns
.export filter_url
.export filter_number

.import get_key

.include "zeropage.inc"
.include "../inc/common.inc"

allowed_ptr = ptr1


.code

; cribbed from http://codebase64.org/doku.php?id=base:robust_string_input
; ======================================================================
; Input a string and store it in GOTINPUT, terminated with a null byte.
; AX is a pointer to the allowed list of characters, null-terminated.
; set AX to $0000 for no filter on input
; max # of chars in y returns num of chars entered in y.
; ======================================================================
; Main entry
get_filtered_input:
  sty MAXCHARS
  stax temp_allowed

  ; Zero characters received.
  lda #$00
  sta INPUT_Y

  ; Wait for a character.
@input_get:
  jsr get_key
  sta LASTCHAR

  cmp #$14                      ; Delete
  beq @delete

  cmp #$0d                      ; Return
  beq @input_done

  ; End reached?
  lda INPUT_Y
  cmp MAXCHARS
  beq @input_get

  ; Check the allowed list of characters.
  ldax temp_allowed
  stax allowed_ptr              ; Since we are reusing this zero page, it may not stil be the same value since last time!

  ldy #$00
  lda allowed_ptr+1             ; Was the input filter point nul?
  beq @input_ok
@check_allowed:
  lda (allowed_ptr),y           ; Overwritten
  beq @input_get                ; Reached end of list (0)

  cmp LASTCHAR
  beq @input_ok                 ; Match found

  ; Not end or match, keep checking
  iny
  jmp @check_allowed

@input_ok:
  lda LASTCHAR                  ; Get the char back
  ldy INPUT_Y
  sta GOTINPUT,y                ; Add it to string
  jsr $ffd2                     ; Print it

  inc INPUT_Y                   ; Next character

  ; Not yet.
  jmp @input_get

@input_done:
  ldy INPUT_Y
  beq  @no_input
  lda #$00
  sta GOTINPUT,y                ; Zero-terminate
  clc
  ldax #GOTINPUT
  rts
@no_input:
  sec
  rts
  ; Delete last character.
@delete:
  ; First, check if we're at the beginning.  If so, just exit.
  lda INPUT_Y
  bne @delete_ok
  jmp @input_get

  ; At least one character entered.
@delete_ok:
  ; Move pointer back.
  dec INPUT_Y

  ; Store a zero over top of last character, just in case no other characters are entered.
  ldy INPUT_Y
  lda #$00
  sta GOTINPUT,y

  ; Print the delete char
  lda #$14
  jsr $ffd2

  ; Wait for next char
  jmp @input_get

; =================================================
; Some example filters
; =================================================
filter_text:
  .byte ",!#'()* "
filter_url:
  .byte ":/%&?+$"
filter_dns:
  .byte "-ABCDEFGHIJKLMNOPQRSTUVWXYZ"
filter_ip:
  .byte "."
filter_number:
  .byte "1234567890",0


.bss

temp_allowed: .res  2
MAXCHARS:     .res  1
LASTCHAR:     .res  1
INPUT_Y:      .res  1
GOTINPUT:     .res 40



; -- LICENSE FOR vic20filteredinput.s --
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
