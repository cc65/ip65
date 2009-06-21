;NB65 API example in DASM format (http://www.atari2600.org/DASM/)
  processor 6502

  include "../inc/nb65_constants.i"

  ;useful macros 
  mac     ldax
    lda     [{1}]
    ldx     [{1}]+1
  endm

  mac     ldaxi
    lda     #<[{1}]
    ldx     #>[{1}]
  endm

  mac     stax
    sta     [{1}]
    stx     [{1}]+1
  endm

  mac cout
    lda [{1}]
    jsr print_a
  endm   

  mac print_cr
    cout #13
    jsr print_a
  endm

  mac nb65call
    ldy [{1}]
    jsr NB65_DISPATCH_VECTOR   
  endm

  mac print
    
    ldaxi [{1}]
    ldy #NB65_PRINT_ASCIIZ
    jsr NB65_DISPATCH_VECTOR   
  endm


;some routines & zero page variables
print_a equ $ffd2
temp_ptr equ $FB ; scratch space in page zero

;######### KERNEL functions
CHKIN     EQU $ffc6
CHKOUT    EQU $ffc9
CHRIN     EQU $ffcf
CHROUT    EQU $ffd2
CLALL     EQU $FFE7
CLOSE     EQU $ffc3
OPEN      EQU $ffc0
READST    EQU $ffb7
SETNAM    EQU $ffbd
SETLFS    EQU $ffba


;start of code
;BASIC stub
  org $801
  dc.b $0b,$08,$d4,$07,$9e,$32,$30,$36,$31,$00,$00,$00
  
  
  ldaxi #NB65_CART_SIGNATURE  ;where signature should be in cartridge (if cart is banked in)
  jsr  look_for_signature
  bcc found_nb65_signature

  ldaxi #NB65_RAM_STUB_SIGNATURE  ;where signature should be in a RAM stub
  jsr  look_for_signature
  bcs nb65_signature_not_found
  jsr NB65_RAM_STUB_ACTIVATE     ;we need to turn on NB65 cartridge
  jmp found_nb65_signature
  
nb65_signature_not_found
  ldaxi #nb65_api_not_found_message
  jsr print_ax
  rts

found_nb65_signature

  print #initializing
  nb65call #NB65_INITIALIZE
	bcc .init_ok
  print_cr
  print #failed
  print_cr
  jsr print_errorcode
  jmp reset_after_keypress    
.init_ok

;if we got here, we have found the NB65 API and initialised the IP stack

  jsr CLALL
.send_1_image
  lda #$93  ;cls
  jsr print_a
  print #signon_message
  jsr reset_counters_to_first_sector
  print #enter_filename
  ldaxi #filter_dns  ;this is pretty close to being a filter for legal chars in file names as well
  jsr get_filtered_input
  bcs .no_filename_entered
  stax nb65_param_buffer+NB65_TFTP_FILENAME
  print #position_cursor_for_track_display
  ldaxi #send_next_block
  stax nb65_param_buffer+NB65_TFTP_POINTER
  ldaxi #nb65_param_buffer
  nb65call #NB65_TFTP_CALLBACK_UPLOAD
  bcc .upload_ok
  print_cr
  print #failed
  jmp print_nb65_errorcode
.upload_ok
  lda #15      ; filenumber 15 - command channel
  jsr CLOSE
  print_cr
  print #ok
  print  #press_a_key_to_continue
  jsr get_key
  jmp .send_1_image ;done! so go again
.no_filename_entered
  rts


send_next_block
;tftp upload callback routine
;AX will point to address to fill
  stax  sector_buffer_address
  lda track
  cmp #36
  beq .past_last_track
  print #position_cursor_for_track_display
  jsr print_current_sector
  jsr read_sector
  lda #$30
  cmp error_buffer
  bne .was_an_error  
.after_error_check
  jsr move_to_next_sector
  bcc .not_last_sector
  ldaxi  #$100
  rts
.not_last_sector
  
  inc sector_buffer_address+1
  jsr read_sector
  jsr move_to_next_sector
  ldaxi  #$200
    
  rts
.past_last_track
  ldaxi  #$0000
  rts

.was_an_error
  print #position_cursor_for_error_display
  print #drive_error
  print_cr
  jsr print_current_sector
  print #error_buffer
  jmp .after_error_check

print_current_sector
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

read_sector
;routine to read a sector cribbed from http://codebase64.org/doku.php?id=base:reading_a_sector_from_disk
; - requires track and sector values be set first
; sector will be written to address whos value is stored in sector_data
; open the channel file

  jsr make_read_sector_command
  
  lda #1
  ldx #<cname
  ldy #>cname
  jsr SETNAM
  lda #$02
  ldx #$08
  ldy #$02
  jsr SETLFS
  jsr OPEN
  bcs .error
  ldx #<command_buffer
  ldy #>command_buffer
  lda #12
  jsr SETNAM
  lda #15
  ldx $BA ;use whatever was last device #
  ldy #15
  jsr SETLFS
  jsr OPEN
  bcs .error
  
  
  jsr check_error_channel
  lda #$30
  cmp error_buffer
  beq .was_not_an_error  
  print #error_buffer
  
.was_not_an_error
  ldx #$02      ; filenumber 2
  jsr CHKIN ;(file 2 now used as input)

  lda sector_buffer_address
  sta temp_ptr
  lda sector_buffer_address+1
  sta temp_ptr+1
  ldy #$00
.loop
  jsr CHRIN ;(get a byte from file)
  sta (temp_ptr),Y   ; write byte to memory
  iny
  bne .loop     ; next byte, end when 256 bytes are read
.close
  lda #15      ; filenumber 15
  jsr CLOSE
  lda #$02      ; filenumber 2
  jsr CLOSE
  ldx #$00      ; filenumber 0 = keyboard
  jsr CHKIN ;(keyboard now input device again)
  rts
.error
  pha
  print #error_opening_channel
  pla
  nb65call #NB65_PRINT_HEX
  jmp .close

check_error_channel
  ldx #$0F      ; filenumber 15
  jsr CHKIN ;(file 15 now used as input)
  ldy #$00
.ecloop
  jsr READST ;(read status byte)
  bne .eof      ; either EOF or read error
  jsr CHRIN ;(get a byte from file)
  sta error_buffer,y
  iny
  jmp .ecloop     ; next byte

.eof
  lda #0
  sta error_buffer,y
  ldx #$00      ; filenumber 0 = keyboard
  jsr CHKIN ;(keyboard now input device again)
  rts

make_read_sector_command
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

byte_to_ascii
  cmp #30
  bmi .not_30
  ldx #$33
  clc
  adc #18
  rts
.not_30  
  cmp #20
  bmi .not_20
  ldx #$32
  clc
  adc #28
  rts
.not_20
  cmp #10  
  bmi .not_10
  ldx #$31
  clc
  adc #38
  rts
.not_10
  ldx #$30
  clc
  adc #48
  rts

move_to_next_sector
  inc sector
  lda sector
  cmp sectors_in_track
  beq .move_to_next_track
  rts
.move_to_next_track:
  lda #0
  sta sector
  inc track
  lda track
  cmp #18
  bne .not_track_18
  lda #19
  sta sectors_in_track
  clc
  rts
.not_track_18
  cmp #25
  bne .not_track_25
  lda #18
  sta sectors_in_track
  clc
  rts
.not_track_25
  cmp #31
  bne .not_track_31
  lda #17
  sta sectors_in_track
  clc
  rts
.not_track_31
  lda track
  cmp #36 ;carry will be set if hit track 36
  rts
  


reset_counters_to_first_sector
  ldx #1
  stx track
  dex
  stx sector
  ldx #21
  stx sectors_in_track
  rts


;look for NB65 signature at location pointed at by AX
look_for_signature subroutine
  stax temp_ptr
  ldy #3
.check_one_byte
  lda (temp_ptr),y
  cmp nb65_signature,y
  bne .bad_match  
  dey 
  bpl .check_one_byte  
  clc
  rts
.bad_match
  sec
  rts

print_ax subroutine
  stax temp_ptr
  ldy #0
.next_char 
  lda (temp_ptr),y
  beq .done
  jsr print_a
  iny
  jmp .next_char
.done
  rts
  
get_key
  jsr $ffe4
  cmp #0
  beq get_key
  rts

reset_after_keypress
  print  #press_a_key_to_continue    
  jsr get_key
  jmp $fce2   ;do a cold start


print_errorcode
  print #error_code
  nb65call #NB65_GET_LAST_ERROR
  nb65call #NB65_PRINT_HEX
  print_cr
  rts

  

;constants
nb65_api_not_found_message dc.b "ERROR - NB65 API NOT FOUND.",13,0
nb65_signature dc.b $4E,$42,$36,$35  ; "NB65"  - API signature
initializing dc.b "INITIALIZING ",13,0
error_code dc.b "ERROR CODE: $",0
press_a_key_to_continue dc.b "PRESS A KEY TO CONTINUE",13,0
failed dc.b "FAILED ", 0
ok dc.b "OK ", 0
  
;variables
nb65_param_buffer DS.B $20  
current_byte DS.B 1
track DS.B 1
sector DS.B 1
sectors_in_track DS.B 1
error_buffer DS.B 128
command_buffer DS.B 128
sector_buffer DS.B 256
sector_buffer_address DS.B 2


