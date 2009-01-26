
OPTIONS_PER_PAGE = 18
.bss

number_of_options: .res 1
current_option: .res 1

first_option_this_page: .res 1
options_shown_this_page: .res 1

option_description_pointers: .res 256  ;table of addresses of up to 128 options

.code


;on entry, AX should point to the list of null terminated option strings to be selected from
;on exit, AX points to the selected string
select_option_from_menu:

  stax  @lda_from_options_source+1
  ldy #0
  sty number_of_options
  
  
@copy_one_pointer:
  jsr @lda_from_options_source
  beq @found_last_option_string
  
  lda   @lda_from_options_source+1
  sta   option_description_pointers,y
  lda   @lda_from_options_source+2
  sta   option_description_pointers+1,y
  iny
  iny  
  beq @found_last_option_string ;if we overflow y, then stop scanning options
  inc number_of_options
  
@scan_for_null_byte:
  jsr @move_to_next_byte
  jsr @lda_from_options_source
  bne @scan_for_null_byte
  
  jsr @move_to_next_byte
  jmp @copy_one_pointer
  
@lda_from_options_source:
  lda $FFFF ;filled in from above
  rts

@move_to_next_byte:
  inc @lda_from_options_source+1
  bne :+
  inc @lda_from_options_source+2
:  
  rts
  
@found_last_option_string:  

@display_first_page_of_options:
  lda   #0
  sta   first_option_this_page

@print_current_page:
  jsr   cls
  ldax  #select_from_following_options
  jsr   print
  
  lda   number_of_options
  cmp   #OPTIONS_PER_PAGE
  bcc   :+
  ldax  #arrow_keys_to_move
  jsr   print
  
:  
  lda   #'('
  jsr   print_a
  lda   #'$'
  jsr   print_a
  lda   first_option_this_page
  sta   current_option
  clc
  adc   #1
  jsr   print_hex
  lda   #'/'
  jsr   print_a
  lda   #'$'
  jsr   print_a
  lda   number_of_options
  jsr   print_hex
  lda   #')'
  jsr   print_a
  jsr   print_cr
  jsr   print_cr
  lda   #0
  sta   options_shown_this_page

@print_loop:
  
  lda   options_shown_this_page 
  clc
  adc   #'A'
  jsr print_a
  
  lda  #')'
  jsr print_a

  lda  #' '
  jsr print_a

  lda   current_option
  asl
  tax
  lda option_description_pointers,x
  tay
  lda option_description_pointers+1,x
  tax
  tya
  jsr print
  jsr print_cr
  
  inc current_option
  lda current_option
  cmp number_of_options
  beq @get_keypress
  inc options_shown_this_page
  lda options_shown_this_page
  cmp #OPTIONS_PER_PAGE
  beq @get_keypress
  jmp @print_loop
  
@get_keypress:
  lda #'?'
  jsr get_key
  cmp #$95
  beq @forward_one_page
  cmp #$8a
  beq @forward_one_page
  cmp #$8b
  beq @back_one_page
  cmp #$88
  beq @back_one_page
  
  ora #$e0      ;make it a lower case letter with high bit set
  sec
  sbc #$e1
  bcc @get_keypress ;if we have underflowed, it wasn't a valid option
  cmp #OPTIONS_PER_PAGE-1
  beq @got_valid_option
  bpl @get_keypress ;if we have underflowed, it wasn't a valid option
  
@got_valid_option:

  clc
  adc first_option_this_page
  cmp number_of_options
  bcs @get_keypress   ;this cmp/bcs is to check the case where we are on the last page of options (which can have less than then
                      ;normal number of options) and have pressed a letter that is not a valid option for this page, but is for all other
                      ;pages.
                      ;a now contains the index of the selected option
  asl   ;double it
  tay
  lda option_description_pointers+1,y
  tax
  lda option_description_pointers,y
  rts


@forward_one_page:  
  clc
  lda first_option_this_page
  adc #OPTIONS_PER_PAGE
  sta first_option_this_page
  cmp number_of_options
  bmi @not_last_page_of_options
@back_to_first_page:    
  jmp @display_first_page_of_options
@not_last_page_of_options:
  jmp @print_current_page

@back_one_page:  
  sec
  lda first_option_this_page
  sbc #OPTIONS_PER_PAGE
  bcc @show_last_page_of_options
  sta first_option_this_page
  jmp @print_current_page
@show_last_page_of_options:
  sec
  lda number_of_options
  sbc #OPTIONS_PER_PAGE
  bcc @back_to_first_page
  sta first_option_this_page
  jmp @print_current_page
;  ldax  #tftp_dir_buffer
;  stax  temp_filename_ptr

.rodata
select_from_following_options: .byte "SELECT ONE OF THE FOLLOWING OPTIONS:",13,0
arrow_keys_to_move: .byte "ARROW KEYS NAVIGATE BETWEEN MENU PAGES",13,0