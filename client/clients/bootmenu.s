;#############
; 
; This program looks for a TNDP server on the network,  presents a catalog of volumes on that server, and allows a volume to be attached
; 
; jonno@jamtronix.com - January 2009
;

  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  .import cls

  .import exit_to_basic
  
	.import copymem
	.importzp copy_src
	.importzp copy_dest

  .import __STARTUP_LOAD__
  .import __STARTUP_SIZE__
  .import __BSS_LOAD__
  .import __DATA_LOAD__
  .import __DATA_RUN__
  .import __DATA_SIZE__
  .import __RODATA_LOAD__
  .import __RODATA_RUN__
  .import __RODATA_SIZE__
  .import __CODE_LOAD__
  .import __CODE_RUN__
  .import __CODE_SIZE__

.segment        "PAGE3"

disable_language_card: .res 3
bin_file_jmp: .res 3

; ------------------------------------------------------------------------

        .segment        "EXEHDR"

        .addr           __STARTUP_LOAD__                ; Start address
        .word           __STARTUP_SIZE__+__CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; Size

; ------------------------------------------------------------------------


.segment        "STARTUP"
  
  
  lda $c089   ;enable language : card read ROM, write RAM, BANK 1
 
  ;copy the monitor rom on to the language card
  ldax #$f800
  stax copy_src
  stax copy_dest  
  ldax #$0800
  jsr startup_copymem

  
  lda $c08b   ;enable language : card read RAM, write RAM, BANK 1
  lda $c08b   ;this soft switch needs to be read twice 


  ;relocate the CODE segment
  ldax #__CODE_LOAD__
  stax copy_src
  ldax #__CODE_RUN__
  stax copy_dest  
  ldax #__CODE_SIZE__
  jsr startup_copymem


  ;relocate the RODATA segment
  ldax #__RODATA_LOAD__
  stax copy_src
  ldax #__RODATA_RUN__
  stax copy_dest  
  ldax #__RODATA_SIZE__
  jsr startup_copymem

  ;relocate the DATA segment
  ldax #__DATA_LOAD__
  stax copy_src
  ldax #__DATA_RUN__
  stax copy_dest  
  ldax #__DATA_SIZE__
  jsr startup_copymem

  jmp init
  
; copy memory
; set copy_src and copy_dest, length in A/X


end: .res 1

startup_copymem:
	sta end
	ldy #0

	cpx #0
	beq @tail

:	lda (copy_src),y
	sta (copy_dest),y
	iny
	bne :-
  inc copy_src+1    ;next page
  inc copy_dest+1  ;next page
	dex
	bne :-

@tail:
	lda end
	beq @done

:	lda (copy_src),y
	sta (copy_dest),y
	iny
	cpy end
	bne :-

@done:
	rts

.code


init:

  jsr cls
  
  ldax  #startup_msg
  jsr print
  jsr print_cr
  
  jmp exit_to_basic
  
	.rodata
startup_msg: .byte "NETBOOT65 FOR APPLE 2  V0.1",13
.byte "SEE README.TXT FOR MORE INFO (INCLUDING",13
.byte "HOW TO RUN SOMETHING MORE INTERESTING)",13
.byte 0


