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
 
 error_buffer = output_buffer + 256
 command_buffer = error_buffer+128
 sector_buffer_address: .res 2

.data
 drive_id: .byte 08  ;default to drive 8
 

.code
 ; init
 ; jsr CLALL

 ;close
;  lda #15      ; filenumber 15 - command channel
;  jsr CLOSE

 ;jsr read_sector
;  lda #$30


;routine to read a sector 
;cribbed from http://codebase64.org/doku.php?id=base:reading_a_sector
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
  jsr make_read_sector_command
@drive_id_set:  
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