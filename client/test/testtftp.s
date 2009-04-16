  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  
  .import exit_to_basic  
  
  .import cfg_get_configuration_ptr
	.import copymem
	.importzp copy_src
	.importzp copy_dest
  
  
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__
  .import  __DATA_SIZE__
  .import tftp_upload
  .import tftp_set_callback_vector
  .import tftp_ip
  .importzp tftp_filename
  
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

.segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-$11                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; Size
        jmp init

.code

init:
  jsr print_cr
  init_ip_via_dhcp 
  jsr print_ip_config

  ldax #upload_callback
  jsr tftp_set_callback_vector
  lda #0
  sta block_number
  ldax #test_file
  stax tftp_filename
  lda #$ff
  ldx #$3
:
  sta tftp_ip,x
  dex
  bpl :-  
  
  ldax #sending
  jsr print
  jsr tftp_upload
  rts

upload_callback:
  stax copy_dest
  ldax #buffer1
  stax copy_src
  inc block_number
  lda block_number
  ldx #00
@next_byte:
  sta buffer1,x
  sta buffer2,x
  inx
  bne @next_byte
  cmp #7
  beq @last_block
  ldax #512    
  jmp :+
@last_block:
  ldax #129
:  
  stax block_length
  jsr copymem
  ldax block_length
  rts
.rodata

test_file: .byte  "TESTFILE.BIN",0
sending: .byte "SENDING...",0

.bss
block_number: .res 1
block_length: .res 2
buffer1: .res 256
buffer2: .res 256