
.include "../inc/nb65_constants.i"
.include "../inc/common.i"

.import ip65_init
.import dhcp_init
.import cs_driver_name
.import cfg_get_configuration_ptr
.export ip65_dispatcher


.code

ip65_dispatcher:

  cpy #NB65_GET_API_VERSION
  bne :+
  ldax  #NB65_API_VERSION
  clc
  rts
:

  cpy #NB65_GET_DRIVER_NAME
  bne :+
  ldax  #cs_driver_name
  clc
  rts
:

  cpy #NB65_GET_IP_CONFIG_PTR
  bne :+
  jmp cfg_get_configuration_ptr
:

  cpy #NB65_INIT_IP
  bne :+
  jmp ip65_init
:

  cpy #NB65_INIT_DHCP
  bne :+
  jmp dhcp_init
:

;default function handler
  lda #$ff  ;function undefined
  sec        ;carry flag set = error
  rts