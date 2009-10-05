
.import io_track_no
.import io_sector_no
.import io_write_sector
.import io_read_sector
  

.segment "APP_SCRATCH"
 track:  .res 1
 sector: .res 1
 errors: .res 1
 sectors_in_track: .res 1
 sector_buffer_address: .res 2  

;the io_* and tftp_* routines both use the 'output_buffer' so we lose the data in the second sector
;therefore we need to copy the data to here before we use it
 sector_buffer: .res 512 
   
.code  
download_d64:    
  stax kipper_param_buffer+KPR_TFTP_FILENAME
  jsr cls
  ldax  #downloading_msg
  jsr print_ascii_as_native
  ldax kipper_param_buffer+KPR_TFTP_FILENAME
  jsr print_ascii_as_native
  jsr reset_counters_to_first_sector  
  ldax #write_next_block
  stax kipper_param_buffer+KPR_TFTP_POINTER
  ldax #kipper_param_buffer
  kippercall #KPR_TFTP_CALLBACK_DOWNLOAD
after_tftp_transfer:  
  bcc :+
  jsr print_cr
  print_failed
  jsr print_errorcode
  jsr print_cr
:
  print_ok
  ldax #press_a_key_to_continue
  jsr print
  jsr get_key
  rts


upload_d64:    
  ldax #enter_filename
  jsr print
  kippercall #KPR_INPUT_HOSTNAME  ;the 'hostname' filter is pretty close to being a filter for legal chars in file names as well
  bcc :+
  rts
:

  stax kipper_param_buffer+KPR_TFTP_FILENAME
  jsr cls
  ;switch to lower case charset
  lda #23
  sta $d018
  ldax  #uploading_msg
  jsr print
  ldax kipper_param_buffer+KPR_TFTP_FILENAME
  jsr print
  jsr reset_counters_to_first_sector  
  ldax #read_next_block
  stax kipper_param_buffer+KPR_TFTP_POINTER
  ldax #kipper_param_buffer
  kippercall #KPR_TFTP_CALLBACK_UPLOAD
  jmp after_tftp_transfer

read_next_block:
;tftp upload callback routine
;AX will point to address to fill
  stax  sector_buffer_address
  lda track
  cmp #36
  beq @past_last_track
  jsr read_sector  
  jsr move_to_next_sector
  bcc @not_last_sector
  ldax  #$100
  rts
@not_last_sector:  
  inc sector_buffer_address+1
  ldax sector_buffer_address
  jsr read_sector  
  jsr move_to_next_sector
  ldax  #$200    
  rts
@past_last_track:
  ldax  #$0000
  rts


save_sector:
  ldax #position_cursor_for_track_display
  jsr print
  jsr print_current_sector
  
  lda track
  sta io_track_no
  
  lda sector
  sta io_sector_no
  
  ldax sector_buffer_address
  jsr io_write_sector
  bcc :+
  inc errors
:  
  jmp move_to_next_sector



read_sector:
  ldax #position_cursor_for_track_display
  jsr print
  jsr print_current_sector
  
  lda track
  sta io_track_no
  
  lda sector
  sta io_sector_no
  
  ldax sector_buffer_address
  jsr io_read_sector
  bcc :+
  inc errors
:  
  jmp move_to_next_sector

write_next_block:
;tftp download callback routine
;AX will point at block to be written (prepended with 2 bytes indicating block length)
  clc       
  adc #02       ;skip the 2 byte length at start of buffer
  bcc :+
  inx
:  
  stax copy_src
  ldax #sector_buffer
  stax copy_dest
  stax  sector_buffer_address  
  ldax #$200
  jsr copymem
  jsr save_sector
    
  bcc @not_last_sector
  rts
@not_last_sector:
  inc sector_buffer_address+1
  jsr save_sector  
  rts
  
@past_last_track:
  rts


print_current_sector:
  ldax #track_no
  jsr print_ascii_as_native
  lda track
  jsr print_hex
  ldax #sector_no
  jsr print_ascii_as_native
  lda sector  
  jsr print_hex
  ldax #errors_msg
  jsr print_ascii_as_native
  lda errors  
  jsr print_hex
  jsr print_cr
  rts
  

reset_counters_to_first_sector:
  ldx #1
  stx track
  dex
  stx sector
  stx errors
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
  cmp #31
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

track_no:
  .byte "TRACK $",0

sector_no:
  .byte " SECTOR $",0
errors_msg:
  .byte " ERRORS $",0
position_cursor_for_track_display:
.byte $13,13,13,0
position_cursor_for_error_display:
.byte $13,13,13,0
enter_filename: .asciiz "FILENAME: "
