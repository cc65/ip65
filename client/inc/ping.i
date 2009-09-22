.import icmp_ping
.import icmp_echo_ip

NUM_PING_RETRIES=3
.bss
ping_retries: .res 1

.code
ping_loop:
  ldax #remote_host
  jsr print
  kippercall #KPR_INPUT_HOSTNAME
  bcc @host_entered
  ;if no host entered, then bail.
  rts
@host_entered:
  stax kipper_param_buffer
  jsr print_cr
  ldax #resolving
  jsr print
  ldax kipper_param_buffer
  kippercall #KPR_PRINT_ASCIIZ
  jsr print_cr
  ldax #kipper_param_buffer
  kippercall #KPR_DNS_RESOLVE
  bcc @resolved_ok
@failed:  
  print_failed
  jsr print_cr
  jsr print_errorcode
  jmp ping_loop
@resolved_ok:

  lda #NUM_PING_RETRIES
  sta ping_retries  
@ping_once:
  ldax #pinging
  jsr print
  ldax #kipper_param_buffer
  jsr print_dotted_quad
  lda #' '
  jsr print_a
  lda #':'
  jsr print_a
  lda #' '
  jsr print_a

  ldax #kipper_param_buffer
  kippercall #KPR_PING_HOST

bcs @ping_error
  jsr print_integer
  ldax #ms
  jsr print
@check_retries:  
  dec ping_retries
  bpl @ping_once
  jmp ping_loop
  
@ping_error:
  jsr print_errorcode
  jmp @check_retries

  
ms: .byte " MS",13,0
pinging: .byte "PINGING ",0
