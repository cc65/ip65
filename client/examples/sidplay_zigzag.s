
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

init_song=$1000
play_song=$1003

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



  ldax #sid_data+2
  stax  copy_src

  ldax $4000
  stax copy_dest

  jsr copymem


  ldax $4000
  stax  copy_src

  ldax $1000
  stax copy_dest

  jsr copymem

  lda #0
  jsr init_song
  jsr install_irq_handler
@loop:
  jmp @loop
  rts  

  

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
  inc $d020
  jsr play_song
  dec $d020
  jmp jmp_old_irq
  



.bss 

.rodata

sid_data:
  ;.incbin "Melonix.sid"
;  .incbin "Power_Train.sid"
  .incbin "zigzag.prg"

included_sid_length=*-sid_data  
.data

irq_handler_installed_flag: .byte 0

jmp_old_irq:
  jmp $ffff




;-- LICENSE FOR sidplay_zigzag.s --
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
