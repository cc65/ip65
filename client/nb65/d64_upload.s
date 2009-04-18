;use the NB65 API to send a d64 disk via TFTP

.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif

.include "../ip65/copymem.s"
.include "../inc/common.i"

.import print_a
.import get_key
.macro cout arg
  lda arg
  jsr print_a
.endmacro   

.data
sector_buffer_address: .word sector_buffer

.bss
 current_byte: .res 1
 track:  .res 1
 sector: .res 1
 sectors_in_track: .res 1
  
 command_buffer: .res 128
 sector_buffer: .res 256
 nb65_param_buffer: .res $20  

  .zeropage
  temp_ptr:		.res 2
  
.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

.word basicstub		; load address

.macro print arg
  ldax arg
	ldy #NB65_PRINT_ASCIIZ
  jsr NB65_DISPATCH_VECTOR 
.endmacro 

.macro print_cr
  lda #13
	jsr print_a
.endmacro

.macro call arg
	ldy arg
  jsr NB65_DISPATCH_VECTOR   
.endmacro

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


;look for NB65 signature at location pointed at by AX
look_for_signature: 
  stax temp_ptr
  ldy #3
@check_one_byte:
  lda (temp_ptr),y
  cmp nb65_signature,y
  bne @bad_match  
  dey 
  bpl@check_one_byte  
  clc
  rts
@bad_match:
  sec
  rts
init:

  print #signon_message

  ldax #NB65_CART_SIGNATURE  ;where signature should be in cartridge
  jsr  look_for_signature
  bcc @found_nb65_signature

  ldax #NB65_RAM_STUB_SIGNATURE  ;where signature should be in RAM
  jsr  look_for_signature
  bcc :+
  jmp nb65_signature_not_found
:  
  jsr NB65_RAM_STUB_ACTIVATE     ;we need to turn on NB65 cartridge
  
@found_nb65_signature:

  print #initializing
  print #nb65_signature
  ldy #NB65_INITIALIZE
  jsr NB65_DISPATCH_VECTOR 
	bcc :+  
  print #failed
  jsr print_errorcode
  jmp bad_boot    
:  
  print #ok
  print_cr
    
; ######################## 
; main program goes here:
; 

  jsr open_drive_channels
  bcs @error  
    
  jsr move_to_first_sector
  
  ldax #test_file  
  stax nb65_param_buffer+NB65_TFTP_FILENAME
  ldax #send_next_block
  stax nb65_param_buffer+NB65_TFTP_POINTER
  ldax #nb65_param_buffer
  call #NB65_TFTP_CALLBACK_UPLOAD
  bcc :+
  jmp print_errorcode
:

  rts
@error:  
  pha
  print #drive_error
  print #error_code
  pla
  call #NB65_PRINT_HEX
  rts


send_next_block:
;tftp upload callback routine
;AX will point to address to fill
  stax  sector_buffer_address
  lda track
  cmp #36
  beq @past_last_track
  jsr print_current_sector
  jsr read_sector
  jsr move_to_next_sector
  bcc @not_last_sector
  ldax  #$100
  rts
@not_last_sector:
  inc sector_buffer_address
  jsr read_sector
  jsr move_to_next_sector
  ldax  #$200
  rts
@past_last_track:
  ldax  #$0000
  rts


print_current_sector:
  lda #$13 ;home
  jsr print_a
  print #track_no
  lda track
  jsr byte_to_ascii
  pha
  txa
  jsr print_a
  pla
  jsr print_a
  print #sector_no
  lda sector
  jsr byte_to_ascii
  pha
  txa
  jsr print_a
  pla
  jsr print_a
  print_cr
  rts

open_drive_channels:  
  LDA #cname_end-cname
  LDX #<cname
  LDY #>cname
  JSR $FFBD     ; call SETNAM
  LDA #$02      ; file number 2
  LDX $BA       ; last used device number
  BNE @skip
  LDX #$08      ; default to device 8
@skip:
  LDY #$02      ; secondary address 2
  JSR $FFBA     ; call SETLFS
  JSR $FFC0     ; call OPEN
  bcc @opened_ok
  rts
@opened_ok:  
  rts
  
dump_sector:
;hex dump sector
  lda #0
  sta current_byte
@dump_byte:
  ldy current_byte
  lda sector_buffer,y
  call #NB65_PRINT_HEX
  inc current_byte
  bne @dump_byte
rts

read_sector:
;routine to read a sector cribbed from http://codebase64.org/doku.php?id=base:reading_a_sector_from_disk
; - requires track and sector values be set first
; sector will be written to address whos value is stored in sector_data
; open the channel file
  
  
      
  jsr make_read_sector_command
  tya
  pha
  print #command_buffer
  print_cr
  pla
  LDX #<command_buffer
  LDY #>command_buffer
  JSR $FFBD     ; call SETNAM
  LDA #$0F      ; file number 15
  LDX $BA       ; last used device number
  LDY #$0F      ; secondary address 15
  JSR $FFBA     ; call SETLFS

  JSR $FFC0     ; call OPEN (open command channel and send U1 command)
  BCS @error    ; if carry set, the file could not be opened

  jsr check_error_channel
  
  LDX #$02      ; filenumber 2
  JSR $FFC6     ; call CHKIN (file 2 now used as input)

  LDA sector_buffer_address
  STA temp_ptr
  LDA sector_buffer_address+1
  STA temp_ptr+1
  LDY #$00
@loop:
  JSR $FFCF     ; call CHRIN (get a byte from file)
  STA (temp_ptr),Y   ; write byte to memory
  INY
  BNE @loop     ; next byte, end when 256 bytes are read
@close:
  LDA #$0F      ; filenumber 15
  JSR $FFC3     ; call CLOSE
  LDX #$00      ; filenumber 0 = keyboard
  JSR $FFC6     ; call CHKIN (keyboard now input device again)
  RTS
@error:  
  pha
  print #drive_error
  print #error_code
  pla
  call #NB65_PRINT_HEX
  JMP @close    ; even if OPEN failed, the file has to be closed


check_error_channel:
  LDA #$00      ; no filename
  LDX #$00
  LDY #$00
  JSR $FFBD     ; call SETNAM
  LDA #$0F      ; file number 15
  LDX $BA       ; last used device number
  BNE @skip
  LDX #$08      ; default to device 8
@skip:
  LDY #$0F      ; secondary address 15 (error channel)
  JSR $FFBA     ; call SETLFS

  JSR $FFC0     ; call OPEN

  LDX #$0F      ; filenumber 15
  JSR $FFC6     ; call CHKIN (file 15 now used as input)

  LDY #$00
@loop:
  JSR $FFB7     ; call READST (read status byte)
  BNE @eof      ; either EOF or read error
  JSR $FFCF     ; call CHRIN (get a byte from file)
  JSR $FFD2     ; call CHROUT (print byte to screen)
  JMP @loop     ; next byte

@eof:
@close:
  LDA #$0F      ; filenumber 15
  JSR $FFC3     ; call CLOSE

  LDX #$00      ; filenumber 0 = keyboard
  JSR $FFC6     ; call CHKIN (keyboard now input device again)
  RTS

bad_boot:
  print  #press_a_key_to_continue
restart:    
  jsr get_key
  jmp $fce2   ;do a cold start


print_errorcode:
  print #error_code
  call #NB65_GET_LAST_ERROR
  call #NB65_PRINT_HEX
  print_cr
  rts

nb65_signature_not_found:

  ldy #0
:
  lda nb65_signature_not_found_message,y
  beq restart
  jsr print_a
  iny
  jmp :-



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
  lda track
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
  lda sector
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
 

move_to_first_sector:
  ldx #1
  stx track
  dex
  stx sector
  ldx #21
  stx sectors_in_track
  rts
  
move_to_next_sector:
  inc sector
  lda sector
  cmp sectors_in_track
  beq @move_to_next_track
  rts
@move_to_next_track:
  lda #0
  sta sector
  inc track
  lda track
  cmp #18
  bne @not_track_18
  lda #19
  sta sectors_in_track
  clc
  rts
@not_track_18:
  cmp #25
  bne @not_track_25
  lda #18
  sta sectors_in_track
  clc
  rts
@not_track_25:
  cmp #25
  bne @not_track_31
  lda #17
  sta sectors_in_track
  clc
  rts
@not_track_31:
  lda track
  cmp #36 ;carry will be set if hit track 36
  rts
  

.rodata

error_code:  
  .asciiz "ERROR CODE: $"
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
  
drive_error:
  .byte "DRIVE ACCESS ERROR - ",0
 nb65_signature_not_found_message:
 .byte "NO NB65 API FOUND",13,"PRESS ANY KEY TO RESET", 0
 
nb65_signature:
  .byte $4E,$42,$36,$35  ; "NB65"  - API signature
  .byte ' ',0 ; so we can use this as a string

test_file: .byte "TEST.D64",0
cname:  .byte 35 ;"#"
cname_end:
