
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

;  jsr dump_dir
  jsr dump_file
  rts
  
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


 rts

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


dump_dir:
  LDA #dirname_end-dirname
  LDX #<dirname
  LDY #>dirname
  JSR $FFBD      ; call SETNAM
  LDA #$02       ; filenumber 2
  LDX $BA
  BNE @skip
  LDX #$08       ; default to device number 8
@skip:
  LDY #$00       ; secondary address 0 (required for dir reading!)
  JSR $FFBA      ; call SETLFS

  JSR $FFC0      ; call OPEN (open the directory)
  BCS @error     ; quit if OPEN failed

  LDX #$02       ; filenumber 2
  JSR $FFC6      ; call CHKIN

  LDY #$04       ; skip 4 bytes on the first dir line
  BNE @skip2
@next:
  LDY #$02       ; skip 2 bytes on all other lines
@skip2:  
  JSR getbyte    ; get a byte from dir and ignore it
  DEY
  BNE @skip2

  JSR getbyte    ; get low byte of basic line number
  TAY
  JSR getbyte    ; get high byte of basic line number
  PHA
  TYA            ; transfer Y to X without changing Akku
  TAX
  PLA
  JSR $BDCD      ; print basic line number
  
  JSR getbyte
  JSR getbyte
  LDA #'#'       ; print a space first
@char:
  JSR $FFD2      ; call CHROUT (print character)
  JSR getbyte
  BNE @char      ; continue until end of line

  LDA #$0D
  JSR $FFD2      ; print RETURN
  JSR $FFE1      ; RUN/STOP pressed?
  BNE @next      ; no RUN/STOP -> continue
@error:
  ; Akkumulator contains BASIC error code

  ; most likely error:
  ; A = $05 (DEVICE NOT PRESENT)
exit:
  LDA #$02       ; filenumber 2
  JSR $FFC3      ; call CLOSE

  LDX #$00
  JSR $FFC9      ; call CHKIN (keyboard now input device again)
  RTS

getbyte:
  JSR $FFB7      ; call READST (read status byte)
  BNE @end       ; read error or end of file
  JMP $FFCF      ; call CHRIN (read byte from directory)
@end:
  PLA            ; don't return to dir reading loop
  PLA
  JMP exit



dump_file:
  LDA #fname_end-fname
  LDX #<fname
  LDY #>fname
  JSR $FFBD     ; call SETNAM
  LDA #$02      ; file number 2
  LDX $BA       ; last used device number
  BNE @skip
  LDX #$08      ; default to device 8
@skip:
  LDY #$02      ; secondary address 2
  JSR $FFBA     ; call SETLFS

  JSR $FFC0     ; call OPEN
  BCS @error    ; if carry set, the file could not be opened

  ; check drive error channel here to test for
  ; FILE NOT FOUND error etc.

  LDX #$02      ; filenumber 2
  JSR $FFC6     ; call CHKIN (file 2 now used as input)


@loop:
  JSR $FFB7     ; call READST (read status byte)
  BNE @eof      ; either EOF or read error
  JSR $FFCF     ; call CHRIN (get a byte from file)
  JSR $FFD2      ; call CHROUT (print character)  
  JMP @loop     ; next byte

@eof:
  AND #$40      ; end of file?
  BEQ @readerror
@close:
  LDA #$02      ; filenumber 2
  JSR $FFC3     ; call CLOSE

  LDX #$00      ; filenumber 0 = keyboard
  JSR $FFC6     ; call CHKIN (keyboard now input device again)
  RTS
@error:
  ; Akkumulator contains BASIC error code
  
  ; most likely errors:
  ; A = $05 (DEVICE NOT PRESENT)
  pha
  ldax #error_code
  jsr print
  pla
  jsr print_hex
  
  JMP @close    ; even if OPEN failed, the file has to be closed
@readerror:
  ; for further information, the drive error channel has to be read
  jsr print_error
  JMP @close


print_error:
  LDX #$0F      ; filenumber 15
  JSR $FFC6     ; call CHKIN (file 15 now used as input)
@loop:
  JSR $FFB7      ; call READST (read status byte)
  BNE @end       ; read error or end of file
  JMP $FFCF      ; call CHRIN (read byte from directory)  
  jsr print_a
  JMP @loop     ; next byte
@end:
  .byte $92
  rts
  
fname:  .byte "tcp.s"
fname_end:


.rodata

error_code:  
  .byte "ERROR CODE: $",0
press_a_key_to_continue:
  .byte "PRESS A KEY TO CONTINUE",13,0

failed:
	.byte "FAILED ", 0

ok:
	.byte "OK ", 0
  
dirname:
  .byte "$"      ; filename used to access directory
dirname_end:

cname: .byte '#'  