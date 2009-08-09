;C64 disk access routines
;


.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif

.include "../inc/common.i"
.export  io_device_no
.export  io_sector_no
.export  io_track_no
.export  io_read_sector
.export  io_read_catalogue

.export io_read_file_with_callback
.export io_filename
.export io_callback

.importzp copy_src
.import ip65_error  
.import output_buffer
;.importzp copy_dest

;reuse the copy_src zero page location
buffer_ptr = copy_src

;######### KERNEL functions
CHKIN   = $ffc6
CHKOUT  = $ffc9
CHRIN = $ffcf
CHROUT  = $ffd2
CLALL = $FFE7
CLOSE = $ffc3
OPEN = $ffc0
READST = $ffb7
SETNAM = $ffbd
SETLFS = $ffba

.bss

 io_track_no:  .res 2
 io_sector_no: .res 1
 io_device_no: .res 1
 io_filename:  .res 2
 error_buffer = output_buffer + 256
 command_buffer = error_buffer+128
 sector_buffer_address: .res 2
 buffer_counter: .res 1
.data
 drive_id: .byte 08  ;default to drive 8

jmp_to_callback:
  jmp $ffff
io_callback=jmp_to_callback+1


write_byte_to_buffer:
tmp_buffer_ptr=write_byte_to_buffer+1
  sta $ffff
  inc tmp_buffer_ptr
  bne :+
  inc tmp_buffer_ptr
:  
  rts


.code

;routine to read a file with a callback after each 256 byte sector
; inputs:
; io_device_number  - specifies drive to use ($00 = same as last time, $01 = first disk (i.e. #8), $02 = 2nd disk (drive #9))
; io_filename - specifies filename to open
; io_callback - address of routine to be called after each sector is read
; AX - address of buffer to read sector into
; outputs:
; on errror, carry flag is set

io_read_file_with_callback:

  stax sector_buffer_address
  jsr parse_filename
  jsr SETNAM

  lda io_device_no
  beq @drive_id_set
  clc
  adc #07   ;so 01->08, 02->09 etc
  sta drive_id
@drive_id_set:  

  lda #$02      ; file number 2
  ldx drive_id
  ldy #02       ; secondary address 2
  jsr SETLFS
  jsr OPEN

  bcs @device_error    ; if carry set, the device could not be addressed

  ;we should now check for file access errors
  jsr open_error_channel
@no_error_opening_error_channel:  
  jsr check_error_channel
  lda #$30
  cmp error_buffer
  
  beq @was_not_an_error  
@readerror:
  lda #NB65_ERROR_FILE_ACCESS_FAILURE
  sta ip65_error
  sec  
  rts
 @was_not_an_error:

@get_next_sector:
  ldx #$02  ;file number 2
  jsr CHKIN ;file 2 now used as input
  
  ldax  sector_buffer_address
  stax  buffer_ptr
  lda #$00
  sta buffer_counter
@get_next_byte:
  jsr READST
  bne @eof
  jsr CHRIN
  ldy buffer_counter
  sta (buffer_ptr),y
  inc buffer_counter
  bne @get_next_byte

  ldy #$00;= 256 bytes
  jsr jmp_to_callback
  jmp @get_next_sector
  
@eof:
  and #$40      ; end of file?
  beq @readerror

  ;we have part loaded a sector
  ldy buffer_counter  
  beq @empty_sector
  jsr jmp_to_callback
@empty_sector:  

@close:
  lda #$02      ; filenumber 2
  jsr CLOSE
  ldx #$00      ;keyboard now used as input
  jsr CHKIN
  clc
  rts
@device_error:
  lda #NB65_ERROR_DEVICE_FAILURE
  sta ip65_error
  ldx #$00
  jsr CHKIN
  sec
  rts
  


;io_filename is null-terminated. 
;this routines sets up up A,X,Y as needed by kernal routines i.e. XY=pointer to name, A = length of name
parse_filename:
  ldax  io_filename
  stax buffer_ptr
  ldy #$ff
@next_byte:
  iny
  lda  (buffer_ptr),y
  bne @next_byte
  tya
  ldx buffer_ptr
  ldy buffer_ptr+1
  rts

;routine to catalogue disk
; io_device_number set to specify drive to use ($00 = same as last time, $01 = first disk (i.e. #8), $02 = 2nd disk (drive #9))
; AX - address of buffer to read catalogue into
; outputs:
; on errror, carry flag is set. 
io_read_catalogue:
  stax  tmp_buffer_ptr  
  
  ;get the BAM
  lda #$12
  sta io_track_no
  lda #00
  sta io_sector_no
  
  ldax #output_buffer
  jsr io_read_sector  
  bcs @end_catalogue

@get_next_catalogue_sector:

  clc
  lda output_buffer 
  beq @end_catalogue
  sta io_track_no
  lda output_buffer+1
  sta io_sector_no
  ldax #output_buffer
  jsr io_read_sector  
  bcs @end_catalogue  
  ldy #0


@read_one_file:
  tya
  pha
  
  lda output_buffer+2,y ;file type
  and #$7f
  beq @skip_to_next_file
  
;  bpl @skip_to_next_file
@get_next_char:
  lda output_buffer+5,y ;file type
  beq @end_of_filename
  cmp #$a0
  beq @end_of_filename
  jsr write_byte_to_buffer
  iny
  jmp @get_next_char
@end_of_filename:  
  lda #0
  jsr write_byte_to_buffer
  pla
  pha
  
  tay ;get Y back to start of this file entry
  lda output_buffer+2,y ;file type
  jsr write_byte_to_buffer  
  lda output_buffer+30,y ;lo byte of file length in sectors
  jsr write_byte_to_buffer
  lda output_buffer+31,y ;hi byte of file length in sectors
  jsr write_byte_to_buffer
@skip_to_next_file:
  pla  
  clc
  adc #$20
  tay
  bne @read_one_file
  jmp @get_next_catalogue_sector
@end_catalogue:  
  lda #0
  jsr write_byte_to_buffer
  jsr write_byte_to_buffer
  rts


;routine to read a sector 
;cribbed from http://codebase64.org/doku.php?id=base:reading_a_sector_from_disk
;inputs:
; io_device_number set to specify drive to use ($00 = same as last time, $01 = first disk (i.e. #8), $02 = 2nd disk (drive #9))
; io_sector_no - set to sector number to be read
; io_track_no - set to track number to be read (only lo byte is used)
; AX - address of buffer to read sector into
; outputs:
; on errror, carry flag is set. otherwise buffer will be filled with 256 bytes

io_read_sector:

  stax sector_buffer_address
  lda io_device_no
  beq @drive_id_set
  clc
  adc #07   ;so 01->08, 02->09 etc
  sta drive_id
@drive_id_set:  
  jsr make_read_sector_command
  lda #1
  ldx #<cname
  ldy #>cname
  jsr SETNAM
  lda #02
  ldx drive_id
  ldy #02
  jsr SETLFS
  jsr OPEN
  bcs @error
  ldx #<command_buffer
  ldy #>command_buffer
  lda #12
  jsr SETNAM
  lda #15
  ldx $BA ;use whatever was last device #
  ldy #15
  jsr SETLFS
  jsr OPEN
  bcs @error  
  
  jsr check_error_channel
  lda #$30
  cmp error_buffer
  beq @was_not_an_error  
  lda #NB65_ERROR_DEVICE_FAILURE
  sta ip65_error
  sec
  rts
 @was_not_an_error:
  ldx #$02      ; filenumber 2
  jsr CHKIN ;(file 2 now used as input)

  lda sector_buffer_address
  sta buffer_ptr
  lda sector_buffer_address+1
  sta buffer_ptr+1
  ldy #$00
@loop:
  jsr CHRIN ;(get a byte from file)
  sta (buffer_ptr),Y   ; write byte to memory
  iny
  bne @loop     ; next byte, end when 256 bytes are read
@close:
  lda #15      ; filenumber 15
  jsr CLOSE
  lda #$02      ; filenumber 2
  jsr CLOSE
  ldx #$00      ; filenumber 0 = keyboard
  jsr CHKIN ;(keyboard now input device again)
  clc
  rts
@error:
  lda #NB65_ERROR_DEVICE_FAILURE
  sta ip65_error
  jmp @close


open_error_channel:
  lda #$00    ; no filename
  tax
  tay
  jsr SETNAM
  lda #$0f    ;file number 15
  ldx drive_id
  ldy #$0f    ; secondary address 15 (error channel)
  jsr SETLFS
  jsr OPEN
  
  rts


check_error_channel:      
  LDX #$0F      ; filenumber 15
  JSR CHKIN ;(file 15 now used as input)
  LDY #$00
@loop:
  JSR READST ;(read status byte)  
  BNE @eof      ; either EOF or read error
  JSR CHRIN ;(get a byte from file)
  sta error_buffer,y
  iny
  
  JMP @loop     ; next byte

@eof:
  lda #0
  sta error_buffer,y
  LDX #$00      ; filenumber 0 = keyboard
  JSR CHKIN ;(keyboard now input device again)
  rts

make_read_sector_command:
;fill command buffer with command to read in track & sector 
;returns length of command in Y

  ldy #0
  lda #85 ;"U"
  sta command_buffer,y
  iny
  lda #$31 ;"1" 
  sta command_buffer,y
  iny
  lda #$20 ;" "
  sta command_buffer,y
  iny
  lda #$32 ;"2" - file number
  sta command_buffer,y
  iny
  lda #$20 ;" "
  sta command_buffer,y
  iny
  lda #$30 ;"0" - drive number
  sta command_buffer,y
  iny
  lda #$20 ;" "
  sta command_buffer,y
  iny
  lda io_track_no
  jsr byte_to_ascii
  pha
  txa
  sta command_buffer,y
  pla
  iny
  sta command_buffer,y
  iny
  lda #$20 ;" "
  sta command_buffer,y
  iny
  lda io_sector_no
  jsr byte_to_ascii
  pha
  txa
  sta command_buffer,y
  pla
  iny
  sta command_buffer,y
  iny
  
  lda #0
  sta command_buffer,y  ;make it ASCIIZ so we can print it
  
  rts

byte_to_ascii:
  cmp #30
  bmi @not_30
  ldx #$33
  clc
  adc #18
  rts
@not_30:  
  cmp #20
  bmi @not_20
  ldx #$32
  clc
  adc #28
  rts
@not_20:
  cmp #10  
  bmi @not_10
  ldx #$31
  clc
  adc #38
  rts
@not_10:
  ldx #$30
  clc
  adc #48
  rts

.rodata
cname: .byte '#'  