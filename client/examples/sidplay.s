
.include "../inc/common.i"
.include "../inc/commonprint.i"

.import cfg_get_configuration_ptr
.import copymem
.importzp copy_src
.importzp copy_dest
.import ascii_to_native

.zeropage
    
.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

.word basicstub		; load address

basicstub:
	.word @nextline
	.word 2003
	.byte $9e 
	.byte <(((init / 1000) .mod 10) + $30)
	.byte <(((init / 100 ) .mod 10) + $30)
	.byte <(((init / 10  ) .mod 10) + $30)
	.byte <(((init       ) .mod 10) + $30)
	.byte 0
@nextline:
	.word 0

init:

  lda #14
  jsr print_a
  ldax #included_sid_length
  stax sidfile_length
  ldax #sid_data
  jsr load_sid
  bcc @ok
  ldax #error
  jmp print
@ok:  
  lda default_song
  jsr init_song
  jsr install_irq_handler
@loop:
  jmp @loop
  rts  

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
  sta init_song+2
  iny
  lda (copy_src),y
  sta init_song+1
  iny
  lda (copy_src),y
  sta play_song+2
  iny
  lda (copy_src),y
  sta play_song+1

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
  
  ldax #init_address
  jsr print
  lda init_song+2
  jsr print_hex
  lda init_song+1
  jsr print_hex
  jsr print_cr
  
  ldax #play_address
  jsr print
  lda play_song+2
  jsr print_hex
  lda play_song+1
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


install_irq_handler:
  ldax  $314    ;previous IRQ handler
  stax  jmp_old_irq+1
  sei ;don't want any interrupts while we fiddle with the vector
  ldax #irq_handler
  stax  $314    ;previous IRQ handler
  sta irq_handler_installed_flag
  cli
  rts

irq_handler:
  lda $d012
  cmp #100
  bne irq_handler
  lda $01
  pha
  lda #$35
  sta $01
  
  inc $d020
  jsr play_song
  dec $d020
  
  pla
  sta $01
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



.bss 
number_of_songs: .res 1
default_song: .res 1
sidfile_address: .res 2
header_length: .res 1
sidfile_length: .res 2

.rodata

songs:
  .byte "SONGS $",0
error:
  .byte "ERROR",13,0
init_address:
  .byte "LOAD ADDRESS $",0
play_address:
  .byte "PLAY ADDRESS $",0

sid_data:
  ;.incbin "Melonix.sid"
;  .incbin "Power_Train.sid"
;  .incbin "Y-Out.sid"
.incbin "outlaw.sid"

included_sid_length=*-sid_data  
.data

irq_handler_installed_flag: .byte 0

init_song:
  jmp $ffff  
play_song:
  jmp $ffff
jmp_old_irq:
  jmp $ffff

