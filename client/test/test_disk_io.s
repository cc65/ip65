
.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif

.include "../inc/common.i"
.include "../inc/commonprint.i"
.import print_a
.import cfg_get_configuration_ptr
.import  io_device_no
.import  io_sector_no
.import  io_track_no
.import  io_read_sector
.import ip65_error

.macro cout arg
  lda arg
  jsr print_a
.endmacro   



.bss
 sector_buffer: .res 256
 output_buffer: .res 520
 .export output_buffer
current_byte: .res 1
  
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
  
  lda #01
  sta io_track_no
  lda #01
  sta io_sector_no
  lda #01
  sta io_device_no
  ldax #sector_buffer
  jsr io_read_sector
  bcs  @error
  
 ; jsr dump_sector ;DEBUG

  lda #$12
  sta io_track_no
  lda #01
  sta io_sector_no
  lda #01
  sta io_device_no
  ldax #sector_buffer
  jsr io_read_sector
  
  bcs  @error
  jsr dump_sector ;DEBUG

@error:
  jsr print_cr
  lda ip65_error
  jsr print_hex
  rts

dump_sector:
;hex dump sector
  lda #0
  sta current_byte
@dump_byte:
  ldy current_byte
  lda sector_buffer,y
  jsr print_hex
  lda sector_buffer,y
  jsr print_a
  inc current_byte
  bne @dump_byte
rts


.rodata

error_code:  
  .byte "ERROR CODE: $",0
press_a_key_to_continue:
  .byte "PRESS A KEY TO CONTINUE",13,0

failed:
	.byte "FAILED ", 0

ok:
	.byte "OK ", 0
  
initializing:  
  .byte "INITIALIZING ",0
track_no:
  .byte "TRACK ",0


sector_no:
  .byte " SECTOR ",0
  
signon_message:
  .byte "D64 UPLOADER V0.1",13,0

enter_filename:
.byte "SEND AS: ",0

drive_error:
  .byte "DRIVE ACCESS ERROR - ",0
 nb65_signature_not_found_message:
 .byte "NO NB65 API FOUND",13,"PRESS ANY KEY TO RESET", 0
 error_opening_channel:
  .byte "ERROR OPENING CHANNEL $",0
 
disk_access:
.byte 13,13,13,13,13,"SENDING TO CHANNEL $",0

nb65_signature:
  .byte $4E,$42,$36,$35  ; "NB65"  - API signature
  .byte ' ',0 ; so we can use this as a string
position_cursor_for_track_display:
;  .byte $13,13,13,13,13,13,13,13,13,13,13,"      SENDING ",0
.byte $13,13,13,"SENDING ",0
position_cursor_for_error_display:
  .byte $13,13,13,13,"LAST ",0

cname: .byte '#'  