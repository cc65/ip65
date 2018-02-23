; minimal telnet implementation (dumb terminal emulation only)

.include "../inc/common.i"
.include "../inc/commonprint.i"
.include "../inc/net.i"
.include "../inc/error.i"

.export start

.import abort_key
.importzp abort_key_default
.importzp abort_key_disable
.import drv_init
.importzp drv_init_default
.import get_filtered_input
.import get_key
.import get_key_if_available
.import exit_to_basic
.import filter_dns
.import filter_number
.import dns_hostname_is_dotted_quad
.import dns_ip
.import dns_resolve
.import dns_set_hostname
.import ip65_process
.import native_to_ascii
.import parse_integer
.import print_cr
.import tcp_callback
.import tcp_close
.import tcp_connect
.import tcp_connect_ip
.import tcp_inbound_data_ptr
.import tcp_inbound_data_length
.import tcp_send
.import tcp_send_data_len
.import tcp_send_keep_alive
.import timer_read
.import vt100_init_terminal
.import vt100_exit_terminal
.import vt100_process_inbound_char
.import vt100_process_outbound_char
.importzp vt100_screen_cols
.importzp vt100_screen_rows

.export telnet_close
.export telnet_send_char
.export telnet_send_string

buffer_ptr = sreg


; keep LD65 happy
.segment "INIT"
.segment "ONCE"


.segment "STARTUP"

  jmp start
drv_init_value:
  .byte drv_init_default


.code

start:
  jsr vt100_init_terminal

; initialize stack
  ldax #welcome_1
  jsr print_vt100
  ldax #welcome_2
  jsr print_vt100
  ldax #initializing
  jsr print_ascii_as_native
  lda drv_init_value
  jsr drv_init
  jsr ip65_init
  bcc :+
  ldax #device_not_found
  jsr print_ascii_as_native
  jmp error_exit
: ldax #eth_driver_name
  jsr print_ascii_as_native
  ldax #io_base_prefix
  jsr print_ascii_as_native
  lda eth_driver_io_base+1
  jsr print_hex
  lda eth_driver_io_base
  jsr print_hex
  ldax #io_base_postfix
  jsr print_ascii_as_native

; get IP addr
  ldax #obtaining
  jsr print_ascii_as_native
  jsr dhcp_init
  bcc :+
  jsr print_error
  jmp error_exit
: ldax #cfg_ip
  jsr print_dotted_quad
  jsr print_cr

telnet_main_entry:
; enter host name
  ldax #remote_host
  jsr print_ascii_as_native
  ldy #40                       ; max chars
  ldax #filter_dns
  jsr get_filtered_input
  bcc :+
  jmp exit

; set host name
: stax buffer_ptr
  ldy #$ff
: iny
  lda (buffer_ptr),y
  jsr native_to_ascii
  cmp #'a'
  bcs :+
  cmp #'A'
  bcc :+
  clc
  adc #'a'-'A'
: sta (buffer_ptr),y
  tax                           ; set Z flag
  bne :--
  ldax buffer_ptr
  jsr dns_set_hostname
  bcc :+
  jsr print_error
  jmp telnet_main_entry

; resolve host name
: lda dns_hostname_is_dotted_quad
  bne :++
  ldax #resolving
  jsr print_ascii_as_native
  jsr dns_resolve
  bcc :+
  jsr print_error
  jmp telnet_main_entry
: ldax #dns_ip
  jsr print_dotted_quad

; enter port
: ldax #remote_port
  jsr print_ascii_as_native
  ldy #5                        ; max chars
  ldax #filter_number
  jsr get_filtered_input
  bcs :+                        ; empty -> default
  jsr parse_integer
  bcc :++
  jmp telnet_main_entry
: ldax #23                      ; default
: stax telnet_port

; connect
  ldax #connecting
  jsr print_ascii_as_native
  ldax #dns_ip
  jsr print_dotted_quad
  ldax #blank
  jsr print_ascii_as_native
  ldax #telnet_callback
  stax tcp_callback
  ldx #3
: lda dns_ip,x
  sta tcp_connect_ip,x
  dex
  bpl :-
  ldax telnet_port
  jsr tcp_connect
  bcc :+
  jsr print_error
  jmp telnet_main_entry

; connected
: ldax #ok
  jsr print_ascii_as_native
  lda #0
  sta connection_close_requested
  sta connection_closed
  sta data_received
  sta iac_response_buffer_length
  lda #abort_key_disable
  sta abort_key
  ldax #on_connect
  jsr print_vt100

@main_polling_loop:
  jsr timer_read
  txa                           ; 1/1000 * 256 = ~ 1/4 seconds
  adc #$20                      ; 32 x 1/4 = ~ 8 seconds
  sta telnet_timeout
@check_timeout:
  lda data_received
  bne :+
  jsr timer_read
  cpx telnet_timeout
  bne :+
  jsr tcp_send_keep_alive
  jmp @main_polling_loop
: lda #0
  sta data_received
  jsr ip65_process
  lda connection_close_requested
  beq :+
  jsr tcp_close
  jmp :++
: lda connection_closed
  beq :++
: lda #abort_key_default
  sta abort_key
  ldax #on_disconnect
  jsr print_vt100
  ldax #disconnected
  jsr print_ascii_as_native
  jmp telnet_main_entry
: lda iac_response_buffer_length
  beq :+
  ldx #0
  stax tcp_send_data_len
  stx iac_response_buffer_length
  ldax #iac_response_buffer
  jsr tcp_send
: jsr get_key_if_available
  bcc @check_timeout
  ldx #0
  stx tcp_send_data_len
  stx tcp_send_data_len+1
  tay
  jsr vt100_process_outbound_char
  jmp @main_polling_loop

print_vt100:
  stax buffer_ptr
  lda #0
  sta buffer_offset
: ldy buffer_offset
  lda (buffer_ptr),y
  bne :+
  rts
: tay
  jsr vt100_process_inbound_char
  inc buffer_offset
  jmp :--

print_error:
  lda ip65_error
  cmp #KPR_ERROR_ABORTED_BY_USER
  bne :+
  ldax #abort
  jmp print_ascii_as_native
: cmp #KPR_ERROR_TIMEOUT_ON_RECEIVE
  bne :+
  ldax #timeout
  jmp print_ascii_as_native
: ldax #error_prefix
  jsr print_ascii_as_native
  lda ip65_error
  jsr print_hex
  jmp print_cr

error_exit:
  ldax #press_a_key_to_continue
  jsr print_ascii_as_native
  jsr get_key
exit:
  jsr vt100_exit_terminal
  jmp exit_to_basic


; vt100 callback - will be executed when the user requests to close the connection
telnet_close:
  lda #1
  sta connection_close_requested
  rts


; vt100 callback - will be executed when sending a char string
telnet_send_string:
  stx buffer_ptr
  sty buffer_ptr+1
  ldy #0
: lda (buffer_ptr),y
  beq send_char
  sta scratch_buffer,y
  inc tcp_send_data_len
  iny
  bne :-
  jmp send_char


; vt100 callback - will be executed when sending a single char
telnet_send_char:
  ldy tcp_send_data_len
  sta scratch_buffer,y
  inc tcp_send_data_len

send_char:
  ldax #scratch_buffer
  jsr tcp_send
  bcs :+
  rts
: lda ip65_error
  cmp #KPR_ERROR_CONNECTION_CLOSED
  bne :+
  lda #1
  sta connection_closed
  rts
: ldax #send_error
  jsr print_ascii_as_native
  jmp print_error


; tcp callback - will be executed whenever data arrives on the TCP connection
telnet_callback:
  lda #1
  ldx tcp_inbound_data_length+1
  cpx #$ff
  bne :+
  sta connection_closed
  rts
: sta data_received
  lda tcp_inbound_data_length
  stax buffer_length
  ldax tcp_inbound_data_ptr
  stax buffer_ptr

@next_byte:
  ldy #0
  lda (buffer_ptr),y
  tax
  ; if we get here, we are in ASCII 'char at a time' mode,
  ; so look for (and process) Telnet style IAC bytes
  lda telnet_state
  cmp #telnet_state_got_command
  bne :+
  jmp @waiting_for_option
: cmp #telnet_state_got_iac
  beq @waiting_for_command
  cmp #telnet_state_got_suboption
  beq @waiting_for_suboption_end
  ; we must be in 'normal' mode
  txa
  cmp #255
  beq :+
  jmp @not_iac
: lda #telnet_state_got_iac
  sta telnet_state
  jmp @byte_processed

@waiting_for_suboption_end:
  txa
  ldx iac_suboption_buffer_length
  sta iac_suboption_buffer,x
  inc iac_suboption_buffer_length
  cmp #$f0                      ; SE - suboption end
  bne @exit_suboption

  lda #telnet_state_normal
  sta telnet_state
  lda iac_suboption_buffer
  cmp #$18
  bne @not_terminal_type

  ldx #0
: lda terminal_type_response,x
  ldy iac_response_buffer_length
  inc iac_response_buffer_length
  sta iac_response_buffer,y
  inx
  txa
  cmp #terminal_type_response_length
  bne :-

@not_terminal_type:
@exit_suboption:
  jmp @byte_processed
@waiting_for_command:
  txa
  sta telnet_command
  cmp #$fa                      ; SB - suboption begin
  beq @suboption
  cmp #$fb                      ; WILL
  beq @option
  cmp #$fc                      ; WONT
  beq @option
  cmp #$fd                      ; DO
  beq @option
  cmp #$fe                      ; DONT
  beq @option
  ; we got a command we don't understand - just ignore it
  lda #telnet_state_normal
  sta telnet_state
  jmp @byte_processed

@suboption:
  lda #telnet_state_got_suboption
  sta telnet_state
  lda #0
  sta iac_suboption_buffer_length
  jmp @byte_processed

@option:
  lda #telnet_state_got_command
  sta telnet_state
  jmp @byte_processed

@waiting_for_option:
  ; we have now got IAC, <command>, <option>
  txa
  sta telnet_option
  lda telnet_command
  cmp #$fb
  beq @iac_will
  cmp #$fc
  beq @iac_wont
  cmp #$fe
  beq @iac_dont
  ; if we get here, then it's a "do"
  lda telnet_option
  cmp #$18                      ; terminal type
  beq @do_terminaltype
  cmp #$1f
  beq @do_naws

  ; if we get here, then it's a "do" command we don't honour
@iac_dont:
  lda #$fc                      ; WONT
@add_iac_response:
  ldx iac_response_buffer_length
  sta iac_response_buffer+1,x
  lda #$ff
  sta iac_response_buffer,x
  lda telnet_option
  sta iac_response_buffer+2,x
  inc iac_response_buffer_length
  inc iac_response_buffer_length
  inc iac_response_buffer_length
@after_set_iac_response:
  lda #telnet_state_normal
  sta telnet_state
  jmp @byte_processed
@iac_will:
  lda telnet_option
  cmp #$01                      ; ECHO
  beq @will_echo
  cmp #$03                      ; DO SUPPRESS GA
  beq @will_suppress_ga
@iac_wont:
  lda #$fe                      ; DONT
  jmp @add_iac_response
@will_echo:
  lda #$fd                      ; DO
  jmp @add_iac_response
@will_suppress_ga:
  lda #$fd                      ; DO
  jmp @add_iac_response

@do_naws:
  ldx #0
: lda naws_response,x
  ldy iac_response_buffer_length
  inc iac_response_buffer_length
  sta iac_response_buffer,y
  inx
  txa
  cmp #naws_response_length
  bne :-
  jmp @after_set_iac_response
@do_terminaltype:
  lda #$fb                      ; WILL
  jmp @add_iac_response

@not_iac:
  txa
  tay
  jsr vt100_process_inbound_char

@byte_processed:
  inc buffer_ptr
  bne :+
  inc buffer_ptr+1
: lda buffer_length+1
  beq :++
  lda buffer_length
  bne :+
  dec buffer_length+1
: dec buffer_length
  jmp @next_byte
: dec buffer_length
  beq :+
  jmp @next_byte
: rts


.rodata

blank:                  .byte " ",0
initializing:           .byte 10,"Initializing ",0
obtaining:              .byte "Obtaining IP address ",0
resolving:              .byte 10,"Resolving to address ",0
connecting:             .byte 10,"Connecting to ",0
io_base_prefix:         .byte " ($",0
io_base_postfix:        .byte ")",10,0
ok:                     .byte "Ok",10,10,0
device_not_found:       .byte "- Device not found",10,0
abort:                  .byte "- User abort",10,0
timeout:                .byte "- Timeout",10,0
error_prefix:           .byte "- Error $",0
remote_host:            .byte 10,"Hostname (leave blank to quit)",10,"? ",0
remote_port:            .byte 10,10,"Port Num (leave blank for default)",10,"? ",0
disconnected:           .byte 10,"Disconnected",10,0
send_error:             .byte "Sending ",0

welcome_1:              .byte 27,")0"
                        .byte 14,"lqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqk"
                        .byte 15,13,10
                        .byte 14,"x                                      x"
                        .byte 15,13,10
                        .byte 14,"x",15,27,"[1m","Telnet65 v1.2",27,"[0m"," based on:               ",14,"x"
                        .byte 15,13,10
                        .byte 14,"x                                      x"
                        .byte 15,13,10,0
welcome_2:              .byte 14,"x",15,"- IP65 (oliverschmidt.github.io/ip65) ",14,"x"
                        .byte 15,13,10
                        .byte 14,"x",15,"- CaTer (www.opppf.de/Cater)          ",14,"x"
                        .byte 15,13,10
                        .byte 14,"x                                      x"
                        .byte 15,13,10
                        .byte 14,"mqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj"
                        .byte 15,13,10
                        .byte 27,")A"
                        .byte 27,"[?25l",0
on_connect:             .byte 27,"[?25h",0
on_disconnect:          .byte 27,"[?25l",27,"[0m",27,"(A",15,0

; initial_telnet_options:
; .byte $ff,$fb,$1F             ; IAC WILL NAWS
; .byte $ff,$fb,$18             ; IAC WILL TERMINAL TYPE
; initial_telnet_options_length = *-initial_telnet_options

terminal_type_response:
  .byte $ff                     ; IAC
  .byte $fa                     ; SB
  .byte $18                     ; TERMINAL TYPE
  .byte $0                      ; IS
  .byte "vt100"                 ; what we pretend to be
  .byte $ff                     ; IAC
  .byte $f0                     ; SE
terminal_type_response_length = *-terminal_type_response

naws_response:
  .byte $ff,$fb,$1f             ; IAC WILL NAWS
  .byte $ff                     ; IAC
  .byte $fa                     ; SB
  .byte $1f                     ; NAWS
  .byte $00                     ; width (high byte)
  .byte vt100_screen_cols       ; width (low byte)
  .byte $00                     ; height (high byte)
  .byte vt100_screen_rows       ; height (low byte)
  .byte $ff                     ; IAC
  .byte $f0                     ; SE
naws_response_length = *-naws_response


.bss

; variables
telnet_port:                    .res 2  ; port number to connect to
telnet_timeout:                 .res 1
connection_close_requested:     .res 1
connection_closed:              .res 1
data_received:                  .res 1
buffer_offset:                  .res 1
telnet_command:                 .res 1
telnet_option:                  .res 1

telnet_state_normal        = 0
telnet_state_got_iac       = 1
telnet_state_got_command   = 2
telnet_state_got_suboption = 3

buffer_length:                  .res 2

telnet_state:                   .res  1
iac_response_buffer:            .res 64
iac_response_buffer_length:     .res  1
scratch_buffer :                .res 40
iac_suboption_buffer:           .res 64
iac_suboption_buffer_length:    .res  1



; -- LICENSE FOR telnet.s --
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
; The Original Code is ip65.
;
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.
; -- LICENSE END --
