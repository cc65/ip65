.import copymem
.import ascii_to_native
.importzp copy_src
.importzp copy_dest
    
.code

load_sid:
  stax sidfile_address
  stax copy_src
  
  ldy #1
  lda (copy_src),y
  cmp #'S'    ;make sure the file starts with 'PSID' or 'RSID'
  beq @ok
  sec
  rts  
@ok:
  ldy #7
  lda (copy_src),y
  sta header_length
  
  inc header_length
  inc header_length
  
  tay
  ;y now points to the start of the real c64 file
  lda (copy_src),y
  sta copy_dest
  iny
  lda (copy_src),y
  sta copy_dest+1

  ldy #$0a
  lda (copy_src),y
  sta init_song_handler+2
  iny
  lda (copy_src),y
  sta init_song_handler+1
  iny
  lda (copy_src),y
  sta play_song_handler+2
  iny
  lda (copy_src),y
  sta play_song_handler+1

  ldy #$0f
  lda (copy_src),y
  sta number_of_songs
  
  ldy #$11
  lda (copy_src),y
  sta default_song
    
  ldy #$16
  jsr print_ascii_string
  
  ldy #$36
  jsr print_ascii_string 
  ldy #$56
  jsr print_ascii_string  
  
  ldax #songs
  jsr print
  
  lda number_of_songs
  jsr print_hex
  jsr print_cr
 
 
  ldax #load_address
  jsr print
  lda copy_dest+1
  jsr print_hex
  lda copy_dest
  jsr print_hex
  jsr print_cr
  
  ldax #play_address
  jsr print
  lda play_song_handler+2
  jsr print_hex
  lda play_song_handler+1
  jsr print_hex
  jsr print_cr
 
 
  ldax #init_address
  jsr print
  lda init_song_handler+2
  jsr print_hex
  lda init_song_handler+1
  jsr print_hex
  jsr print_cr
  
  ldax sidfile_address
  stax  copy_src

  
  clc
  lda sidfile_address
  adc header_length
  pha
  lda sidfile_address+1
  adc #0
  tax
  pla
  stax copy_src
  sec
  lda sidfile_length
  sbc header_length
  pha
  lda sidfile_length+1
  sbc #0
  tax
  pla
  jsr copymem

  clc
  rts

play_sid:
  
  lda default_song
  sta current_song
  jsr init_song
  jsr install_irq_handler
  jsr print_current_song
@keypress_loop:
  jsr get_key_ip65
  cmp #KEYCODE_ABORT
  bne @not_abort
  jsr remove_irq_handler
  jsr reset_sid
  rts
  
@not_abort:
  
  cmp #KEYCODE_DOWN
  bne @not_down
  dec current_song
  bne :+
  inc current_song
:
  jmp @reset_song
@not_down:  

  

  cmp #KEYCODE_UP
  bne @not_up
  lda current_song
  cmp number_of_songs
  beq :+
  inc current_song  
:  
  jmp @reset_song
@not_up:
  jmp @keypress_loop  
  
@reset_song:  
  jsr print_current_song
  jsr init_song
  jmp @keypress_loop  


print_current_song:
  
  ldax #song_number
  jsr print
  lda current_song
  jsr print_hex
  rts
reset_sid:
  lda	#$00			
	sta	$D404
	sta	$D40B
	sta	$D412
	sta	$D418
  rts
  
remove_irq_handler:  
  ldax  jmp_old_irq+1
  sei ;don't want any interrupts while we fiddle with the vector
  stax  $314    ;previous IRQ handler
  cli
  rts
  
install_irq_handler:
  ldax  $314    ;previous IRQ handler
  stax  jmp_old_irq+1
  sei ;don't want any interrupts while we fiddle with the vector
  ldax #irq_handler
  stax  $314    ;previous IRQ handler  
  cli
  rts

irq_handler:
  
  lda play_song_handler+2
  beq :+
  lda $d012
  cmp #100
  bne irq_handler

  
  inc $d020
  jsr play_song
  dec $d020
:  
  jmp jmp_old_irq
  

print_ascii_string:
:  
  lda (copy_src),y
  beq :+
  jsr ascii_to_native  
  jsr print_a
  iny
  bne :-
  :
  jmp print_cr



.segment "APP_SCRATCH"
number_of_songs: .res 1
default_song: .res 1
sidfile_address: .res 2
header_length: .res 1
sidfile_length: .res 2
current_song: .res 1
.rodata

songs:
  .byte "SONGS $",0
error:
  .byte "ERROR",13,0
load_address:
  .byte "LOAD ADDRESS $",0
play_address:
  .byte "PLAY ADDRESS $",0
init_address:
  .byte "INIT ADDRESS $",0

song_number:
  .byte 19,17,17,17,17,17,17,17,"CURRENT SONG NUMBER $",0

.segment "SELF_MODIFIED_CODE"


init_song:
  lda $01
  pha
  lda #$35
  sta $01 
  lda current_song
init_song_handler:
  jsr $ffff  
  pla
  sta $01
  rts
  
  
play_song:
  lda $01
  pha
  lda #$35
  sta $01 
play_song_handler:
  jsr $ffff 
  pla
  sta $01
  rts

jmp_old_irq:
  jmp $ffff




;-- LICENSE FOR sidplay.i --
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
