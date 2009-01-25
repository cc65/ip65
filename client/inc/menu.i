
OPTIONS_PER_PAGE = 5
.bss

number_of_options: .res 1
current_option: .res 1

first_option_this_page: .res 1
options_shown_this_page: .res 1

option_description_pointers: .res 256  ;table of addresses of up to 128 filenames

.code


select_option_from_menu:

@display_first_page_of_options:
  lda   #0
;  lda   #15
  sta   first_option_this_page

@print_current_page:
  jsr   cls
  ldax  #select_from_following_options
  jsr   print
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
  lda   #0
  sta   options_shown_this_page

@print_loop:
  
  lda   options_shown_this_page 
  clc
  adc   #'A'
  jsr print_a
  
  lda  #'-'
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
  jsr get_key
;  jsr print_hex  ;for debugging
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
  bpl@get_keypress ;if we have underflowed, it wasn't a valid option
  
@got_valid_option:

  clc
  adc first_option_this_page
  cmp number_of_options
  bcs @get_keypress   ;this cmp/bcs is to check the case where we are on the last page of options (which can have less than then
                      ;normal number of options) and have pressed a letter that is not a valid option for this page, but is for all other
                      ;pages.
  rts
jmp @get_keypress

@forward_one_page:  
  clc
  lda first_option_this_page
  adc #OPTIONS_PER_PAGE
  sta first_option_this_page
  cmp number_of_options
  bmi @not_last_page_of_options
  jmp @display_first_page_of_options
@not_last_page_of_options:
  jmp @print_current_page

@back_one_page:  
  sec
  lda first_option_this_page
  sbc #OPTIONS_PER_PAGE
  bcc @show_last_page_of_options
@back_to_first_page:  
  sta first_option_this_page
  jmp @print_current_page
@show_last_page_of_options:
  sec
  lda number_of_options
  sbc #OPTIONS_PER_PAGE
  sta first_option_this_page
  jmp @print_current_page
;  ldax  #tftp_dir_buffer
;  stax  temp_filename_ptr

.rodata
select_from_following_options: .byte "SELECT ONE OF THE FOLLOWING OPTIONS:",13,0