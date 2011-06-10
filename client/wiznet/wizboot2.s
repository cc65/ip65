
.include "../inc/common.i"
.import cfg_get_configuration_ptr
.include "../inc/commonprint.i"

.include "../drivers/w5100.i"

IP_CONFIG_SNAPSHOT=$200

.import copymem
.importzp copy_src
.importzp copy_dest
.import ip_init
.import arp_init
.import timer_init
.import cfg_mac
.import cfg_size
.import url_download
.import url_download_buffer
.import url_download_buffer_length


.import  __DATA_LOAD__
.import  __DATA_RUN__
.import  __DATA_SIZE__
.import  __SELF_MODIFIED_CODE_LOAD__
.import  __SELF_MODIFIED_CODE_RUN__
.import  __SELF_MODIFIED_CODE_SIZE__

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

	;copy IP parameters & MAC address that we stashed in the 'stage 1' loader

	ldax #IP_CONFIG_SNAPSHOT
	stax copy_src
	ldax  #cfg_mac
	stax copy_dest
	ldax  #cfg_size
	jsr copymem
	  
	jsr timer_init		; initialize timer
	jsr arp_init		; initialize arp
	jsr ip_init			; initialize ip, icmp, udp, and tcp

	ldax #download_buffer
	stax url_download_buffer
	ldax #download_buffer_length
	stax url_download_buffer_length
	ldax #banner
	jsr	print
	ldax #initial_resource_file
	jsr	get_resource_file
	

@loop:
	jmp	@loop
	rts

get_resource_file:
	stax resource_file
	ldax #retrieving
	jsr	print_ascii_as_native
	ldax resource_file
	jsr	print_ascii_as_native
	ldax resource_file
	jsr	url_download
	bcc @download_ok
	print_failed
	jsr print_errorcode
	rts
@download_ok:
	ldax #download_buffer
	jsr	print_ascii_as_native
	rts
	
.rodata
banner: 
.byte 147	;cls
.byte 14	;lower case
.byte "wIZnET lOADER - sTAGE 2",13,0
retrieving: .asciiz "Fetch "
initial_resource_file: .byte "http://jamtronix.com/c64files.txt",0
.bss
resource_file: .res 2
download_buffer: .res 8192
download_buffer_length=*-download_buffer

;-- LICENSE FOR wizboot2.s --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
; 
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
; 
; The Original Code is wizboot2.
; 
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2011
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
