.include "../inc/ip65_function_numbers.i"

.import ip65_init
.import dhcp_init

.export ip65_dispatcher


.code

ip65_dispatcher:

  cpy #FN_IP65_INIT
  bne :+
  jmp ip65_init
:

  cpy #FN_DHCP_INIT
  bne :+
  jmp dhcp_init
:

;default function handler
  lda #$ff  ;function undefined
  sec        ;carry flag set = error
  rts