  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  .include "../inc/char_conv.i"
  .include "../inc/c64keycodes.i"

  .import get_key
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__
  .import  __DATA_SIZE__

  .import mul_8_16
  .importzp acc16

  .importzp copy_src
  .importzp copy_dest
  .import copymem

  .import cls
.segment "IP65ZP" : zeropage

; pointer for moving through buffers
buffer_ptr:	.res 2			; source pointer


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


current_resource_history_entry: .byte 0

.bss 

DISPLAY_LINES=20
page_counter: .res 1
MAX_PAGES = 50
page_pointer_lo: .res MAX_PAGES
page_pointer_hi: .res MAX_PAGES

resource_counter: .res 1
MAX_RESOURCES = DISPLAY_LINES

resource_pointer_lo: .res MAX_RESOURCES
resource_pointer_hi: .res MAX_RESOURCES
resource_type: .res MAX_RESOURCES

this_is_last_page: .res 1


temp_ax: .res 2

current_resource:
resource_hostname: .res 64
resource_port: .res 2
resource_selector: .res 160

RESOURCE_HISTORY_ENTRIES=8
resource_history:
.res $100*RESOURCE_HISTORY_ENTRIES

.code

init:
  
  lda #14
  jsr print_a ;switch to lower case

  ldax #initial_location
  sta resource_pointer_lo
  stx resource_pointer_hi
  ldx #0
  jsr  show_resource
  rts

show_buffer:

  ldax #input_buffer
  stax  get_next_byte+1
  
  lda #0
  sta page_counter
 
@do_one_page:  
  jsr cls

  ldax  #page_header
  jsr print
  lda page_counter
  jsr print_hex
  
  jsr print_resource_description
  ldx page_counter
  lda get_next_byte+1
  sta page_pointer_lo,x
  lda get_next_byte+2
  sta page_pointer_hi,x
  inc page_counter
  
  lda #0
  sta resource_counter


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
  sec  
  lda get_next_byte+1
  sbc #1  ;since "get_next_byte" did the inc, we need to backtrack 1 byte
  sta resource_pointer_lo,x
  lda get_next_byte+2
  sbc #0  ;in case there was an overflow on the low byte
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
  cmp #DISPLAY_LINES
  bmi @next_line
  lda #0
  sta this_is_last_page
@done:
@get_keypress:
  jsr get_key
  cmp #' '
  beq @go_next_page  
  cmp #KEYCODE_F7
  beq @go_next_page
  cmp #KEYCODE_DOWN
  beq @go_next_page
  cmp #KEYCODE_F1
  beq @go_prev_page
  cmp #KEYCODE_UP
  beq @go_prev_page
  cmp #KEYCODE_F2
  beq @show_history
  cmp #KEYCODE_LEFT
  beq @back_in_history
  cmp #KEYCODE_F3
  beq @back_in_history
  cmp #KEYCODE_ABORT
  
  beq @quit
  ;if fallen through we don't know what the keypress means, go get another one
  and #$7f  ;turn off the high bit 
  sec
  sbc #$40
  bmi @not_a_resource
  cmp resource_counter
  beq @valid_resource
  bcs @not_a_resource  
@valid_resource:  
  tax
  dex
  jsr show_resource
@not_a_resource:  
  jsr print_hex
  jmp @get_keypress  
@back_in_history:
  ldx current_resource_history_entry
  dex 
  beq @get_keypress ;if we were already at start of history, can't go back any further
  stx current_resource_history_entry
  txa
  jsr load_resource_from_history
  jmp show_buffer
@show_history:
  jmp show_history
@go_next_page:  
  lda this_is_last_page
  bne @get_keypress

  jmp @do_one_page
@quit:
  rts
@go_prev_page:  
  ldx page_counter  
  dex  
  bne @not_first_page
  jmp @get_keypress
@not_first_page:  
  dex
  dec page_counter
  dec page_counter
  
  lda page_pointer_lo,x  
  sta get_next_byte+1
  lda page_pointer_hi,x
  sta get_next_byte+2
  jmp @do_one_page

;get a gopher resource 
;X should be the selected resource number
;the resources selected should be loaded into resource_pointer_* 

show_resource:
  lda resource_pointer_lo,x
  sta buffer_ptr
  lda resource_pointer_hi,x
  sta buffer_ptr+1
  ldy #0  
  ldx #0
  jsr @skip_to_next_tab
;should now be pointing at the tab just before the selector
@copy_selector:
  iny 
  lda (buffer_ptr),y
  cmp #09
  beq @end_of_selector
  sta resource_selector,x
  inx
  jmp @copy_selector
@end_of_selector:  
  lda  #$00
  sta resource_selector,x
  tax
;should now be pointing at the tab just before the hostname
@copy_hostname:
  iny 
  lda (buffer_ptr),y
  cmp #09
  beq @end_of_hostname
  sta resource_hostname,x
  inx
  jmp @copy_hostname

@end_of_hostname:  
  lda  #$00
  sta resource_hostname,x

;should now be pointing at the tab just before the port number
  lda #0
  sta resource_port
  sta resource_port+1
@parse_port:  
  iny  
  beq @end_of_port
  lda (buffer_ptr),y
  cmp #$0D
  beq @end_of_port

  ldax  resource_port
  stax  acc16
  lda #10
  jsr mul_8_16
  ldax  acc16
  stax  resource_port
  lda (buffer_ptr),y
  sec
  sbc #'0'
  clc
  adc resource_port
  sta resource_port
  bcc :+  
  inc resource_port+1
:  
  jmp @parse_port  
@end_of_port:  
@done:      
  ;add this to the resource history
  lda current_resource_history_entry
  cmp #RESOURCE_HISTORY_ENTRIES
  bne @dont_shuffle_down  
  ldax  #resource_history
  stax  copy_dest
  inx   ;one page higher up
  stax  copy_src
  ldx #(RESOURCE_HISTORY_ENTRIES-1)
  lda #$00
  jsr copymem
  dec current_resource_history_entry

@dont_shuffle_down:  
  ldax  #current_resource
  stax copy_src
  lda  #<resource_history
  sta  copy_dest
  clc
  lda  #>resource_history
  adc current_resource_history_entry
  sta copy_dest+1
  ldax #$100
  jsr copymem
  
  inc current_resource_history_entry  
  jmp show_buffer
  
@skip_to_next_tab:  
  iny
  beq @done_skipping_over_tab 
  lda (buffer_ptr),y
  cmp #$09
  bne @skip_to_next_tab
@done_skipping_over_tab:  
  rts

;show the entries in the history buffer
show_history:
  
  jsr cls
  ldax #history
  jsr print
  
  lda current_resource_history_entry
@show_one_entry:
  pha
  jsr load_resource_from_history
  jsr print_resource_description
  pla
  sec
  sbc #1
  bne @show_one_entry
  
  
  jsr get_key
  jmp show_buffer


;retrieve entry specified by A from resource history
;NB 'A' = 1 means the first entry
load_resource_from_history:
  clc
  adc  #(>resource_history)-1
  sta copy_src+1
  lda  #<resource_history
  sta  copy_src

  ldax  #current_resource
  stax copy_dest
  ldax #$100
  jsr copymem

  rts

print_resource_description:
ldax #port_no
  jsr print
  lda resource_port+1
  jsr print_hex
  lda resource_port
  jsr print_hex  
  jsr print_cr
  ldax #resource_hostname
  jsr print
  ldax #resource_selector
  jsr print  
  jsr print_cr
  rts
  
.rodata
input_buffer:
.incbin "rob_gopher.txt"
.incbin "retro_gopher.txt"
.byte 0
page_header:
.byte "PAGE NO $",0
port_no:
.byte "PORT NO ",0
history:
.byte "gopher history ",13,0

initial_location:
.byte "1luddite",$09,"/luddite/",$09,"retro-net.org",$09,"70",$0D,$0A,0
