  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  .include "../inc/char_conv.i"

  .import get_key
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__
  .import  __DATA_SIZE__

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


.data
get_next_byte:
  lda $ffff
  inc get_next_byte+1
  bne :+
  inc get_next_byte+2
:  
  rts

.bss 

page_counter: .res 1
MAX_PAGES = 10
page_pointer_lo: .res MAX_PAGES
page_pointer_hi: .res MAX_PAGES

resource_counter: .res 1
MAX_RESOURCES = 25

resource_pointer_lo: .res MAX_RESOURCES
resource_pointer_hi: .res MAX_RESOURCES
resource_type: .res MAX_RESOURCES

this_is_last_page: .res 1

.code

init:
  
  jsr  show_buffer
  rts

show_buffer:

  ldax #input_buffer
  stax  get_next_byte+1
  
  lda #0
  sta resource_counter
  
  lda #14
  jsr print_a ;switch to lower case

@do_one_page:  

  ldx page_counter
  lda get_next_byte+1
  sta page_pointer_lo  
  lda get_next_byte+2
  sta page_pointer_hi
  inc page_counter
  
  lda #0
  sta resource_counter

  lda #147  ; 'CLR/HOME'
  jsr print_a

@next_line:
  jsr get_next_byte
  cmp #'.'
  bne @not_last_line
  lda #1
  sta this_is_last_page
  jmp @done
@not_last_line:  
  cmp #'i'
  beq @info_line
  cmp #'0'
  beq @standard_resource
  cmp #'1'
  beq @standard_resource

  ;if we got here, we know not what it is  
  jmp @skip_to_end_of_line  
@standard_resource:  
  ldx resource_counter
  sta resource_type,x
  lda get_next_byte+1
  sta resource_pointer_lo,x
  lda get_next_byte+2
  sta resource_pointer_hi,x
  inc resource_counter
  lda $d3
  beq :+
  jsr print_cr
:  
  lda #18
  jsr print_a
  lda resource_counter
  clc
  adc #'a'-1
  jsr print_a
  lda #146
  jsr print_a
  lda #' '
  jsr print_a

@info_line:  
@print_until_tab:
@next_byte:
  jsr get_next_byte
  cmp #$09
  beq @skip_to_end_of_line
  tax
  lda ascii_to_petscii_table,x
  jsr print_a
  jmp @next_byte
  
@skip_to_end_of_line:
  jsr get_next_byte
  cmp #$0A
  bne @skip_to_end_of_line
  lda $d3
  cmp #0
  beq :+
  jsr print_cr
:  
  lda $d6
  cmp #23
  bmi @next_line
  lda #0
  sta this_is_last_page
@done:

  jsr get_key
  
  lda this_is_last_page
  bne @last_page
  jmp @do_one_page
@last_page:  
  rts

.rodata
input_buffer:
.incbin "rob_gopher.txt"
.incbin "retro_gopher.txt"
.byte 0