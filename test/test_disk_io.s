
.ifndef KIPPER_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.include "../inc/common.i"
.include "../inc/commonprint.i"
.import print_a
.import cfg_get_configuration_ptr
.import  io_device_no
.import  io_sector_no
.import  io_track_no
.import  io_read_sector
.import  io_write_sector
.import io_read_file_with_callback
.import io_read_file
.import io_filename
.import io_filesize
.import io_load_address
.import io_callback
.import get_key
.import ip65_error
.import io_read_catalogue_ex

.macro cout arg
  lda arg
  jsr print_a
.endmacro   



.bss
 sector_buffer: .res 256
 output_buffer: .res 520
 .export output_buffer
current_byte_in_row: .res 1
current_byte_in_sector: .res 1
start_of_current_row: .res 1

directory_buffer: .res 4096

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

  ;switch to lower case charset
  lda #23
  sta $d018

  ;test we can read catalogue the hard way
  ldax #loading
  jsr print
  ldax #dir_fname
  stax io_filename
  jsr print


  jsr print_cr
  lda #01
  sta io_device_no

  ldax #readfile_callback
  stax  io_callback
  ldax  #$3000
  jsr io_read_file
  bcc :+
  jsr print_error_code
  rts
:  



  ;test we can write sector to default desk
  
  ldx #$00
@fill_sector_loop:  
  txa
  sta sector_buffer,x
  inx  
  bne @fill_sector_loop
  
  lda #$01
  sta io_track_no
  lda #$01
  sta io_sector_no
  ldax #write_sector
  jsr print
  lda io_sector_no
  jsr print_hex
  jsr print_cr
  ldax #sector_buffer  
  jsr io_write_sector
  
  bcc :+
  jsr print_error_code
  rts
:



  inc io_sector_no
  ldax #write_sector
  jsr print
  lda io_sector_no
  jsr print_hex
  jsr print_cr
  ldax #sector_buffer
  jsr io_write_sector
  
  bcc :+
  jsr print_error_code
  rts
:

  inc io_sector_no
  ldax #write_sector
  jsr print
  lda io_sector_no
  jsr print_hex
  jsr print_cr
  ldax #sector_buffer
  jsr io_write_sector
  
  bcc :+
  jsr print_error_code
  rts
:



  ;test we can read a sector from default desk
  ldax #read_sector
  jsr print

  lda #$01
  sta io_track_no
  lda #$03
  sta io_sector_no
  ldax #sector_buffer
  jsr io_read_sector
  bcc :+
  jsr print_error_code
  rts
:
  
  jsr dump_sector
  
  ;test we can read the catalogue
  ldax #read_catalogue
  jsr print  

  lda #01
  sta io_device_no

  ldax #directory_buffer
  jsr io_read_catalogue_ex
  
  bcc @no_error_on_catalogue
  jsr print_error_code
  rts
@no_error_on_catalogue:  
  ldax #directory_buffer
  jsr print_catalogue

  ;test we can read without callbacks to fixed buffer
   ldax #loading
  jsr print
  ldax #fname
  stax io_filename
  jsr print


  jsr print_cr
  lda #01
  sta io_device_no

  ldax #readfile_callback
  stax  io_callback
  ldax  #$3000
  jsr io_read_file
  bcc :+
  jsr print_error_code
  rts
:  

  ldax io_filesize
  jsr print_integer
  ldax #bytes_to
  jsr print
  lda io_load_address+1
  jsr print_hex
  lda io_load_address
  jsr print_hex
  jsr print_cr


;test we can read without callbacks to address in file
   ldax #loading
  jsr print
  ldax #fname2
  stax io_filename
  jsr print


  jsr print_cr
  lda #01
  sta io_device_no

  ldax #readfile_callback
  stax  io_callback
  ldax  #$0000
  jsr io_read_file
  bcc :+
  jsr print_error_code
  rts
:  

  ldax io_filesize
  jsr print_integer
  ldax #bytes_to
  jsr print
  lda io_load_address+1
  jsr print_hex
  lda io_load_address
  jsr print_hex
  jsr print_cr

  jsr wait_for_keypress
  
  ;test we can read via callbacks

  ldax #loading
  jsr print
  ldax #fname
  stax io_filename
  jsr print

  jsr print_cr
  lda #01
  sta io_device_no

  ldax #readfile_callback
  stax  io_callback
  ldax  #sector_buffer
    
  jsr io_read_file_with_callback
  bcc :+
  jsr print_error_code
:  


  
  rts
  
 
@error:
  jsr print_cr
  lda ip65_error
  jsr print_hex
  rts


;print catalogue pointed at by AX
print_catalogue:
  stax tmp_buffer_ptr

 @print_one_filename:
  jsr read_byte_from_buffer
  beq @catalogue_done
@print_one_char:
  jsr print_a
  jsr read_byte_from_buffer
  beq @end_of_filename
  jmp @print_one_char
@end_of_filename:
    jsr print_cr
  ldax #filetype
  jsr print
  jsr read_byte_from_buffer
  jsr print_hex
  ldax #sectors
  jsr print
  jsr read_byte_from_buffer
  pha
  jsr read_byte_from_buffer
  jsr print_hex
  pla
  jsr print_hex
  jsr print_cr
  jmp @print_one_filename
@catalogue_done:
  rts

read_byte_from_buffer:
tmp_buffer_ptr=read_byte_from_buffer+1
  lda $ffff
  inc tmp_buffer_ptr
  bne :+
  inc tmp_buffer_ptr+1
:  
  pha
  pla ;reload A so flags are set correctly
  rts



readfile_callback:
  tya
  jsr print_hex
  ldax #bytes
  jsr print
  jsr dump_sector
  rts

print_error_code:
  jsr print_cr
  ldax  #error
  jsr print  
  lda ip65_error
  jsr print_hex
  jsr print_cr
  rts

wait_for_keypress:
  lda #0
  sta $c6 ;set the keyboard buffer to be empty
  ldax  #press_a_key_to_continue
  jsr print
  jsr get_key  
  rts

dump_sector:
;hex dump sector
  lda #0
  sta current_byte_in_sector
  sta start_of_current_row
  
@one_row:
  lda #$80
  cmp current_byte_in_sector
  bne @dont_wait_for_key
  jsr wait_for_keypress
@dont_wait_for_key:  
  lda current_byte_in_sector
  
  sta start_of_current_row
  jsr print_hex
  lda #':'
  jsr print_a
  lda #' '
  jsr print_a

  lda #0
  sta current_byte_in_row
  
;first the hex values  
@dump_byte:
  ldy current_byte_in_sector
  lda sector_buffer,y
  jsr print_hex
  lda #' '
  jsr print_a
  inc current_byte_in_sector
  inc current_byte_in_row
  lda current_byte_in_row
  cmp #08
  bne @dump_byte
  
;now the ascii values
  lda start_of_current_row
  sta current_byte_in_sector
@print_byte:
  ldy current_byte_in_sector
  lda sector_buffer,y
  cmp #32
  bmi @not_printable
  cmp #94
  bmi @printable
@not_printable:
  lda #'.'
@printable:
  jsr print_a
  inc current_byte_in_sector
  beq @last_byte
  dec current_byte_in_row
  bne @print_byte
  jsr print_cr
  jmp @one_row
@last_byte:
  jsr print_cr
  jsr wait_for_keypress
  rts



write_sector:
  .byte "WRITING SECTOR",0

read_sector:
  .byte "READING SECTOR",13,0


dir_fname: .byte "$",0

read_catalogue:
  .byte "READING CATALOGUE",13,0
fname:  
  .byte "TEST_DISK_IO.PRG",0

fname2:
  .byte "SCREEN.PRG",0

loading: .byte "LOADING ",0
.rodata

filetype:
  .byte "TYPE: $",0

sectors:
  .byte " SECTORS: $",0
error:
	.byte "ERROR - $", 0

failed:
	.byte "FAILED ", 0

ok:
	.byte "OK ", 0

bytes:
	.byte " BYTES.", 0

bytes_to:
	.byte " BYTES TO $", 0




;-- LICENSE FOR test_disk_io.s --
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
