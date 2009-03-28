
.include "../inc/nb65_constants.i"
.include "../inc/common.i"

.export nb65_dispatcher

.import ip65_init
.import dhcp_init
.import cs_driver_name
.import cfg_get_configuration_ptr
.import tftp_load_address
.importzp tftp_filename
.import tftp_ip
.import tftp_directory_listing
.import ip65_error
.import tftp_clear_callbacks
.import tftp_download

.zeropage
nb65_params:		.res 2

.code


set_tftp_params:
  stax nb65_params
  ldy #NB65_TFTP_IP
  lda (nb65_params),y
  sta tftp_ip
  iny
  lda (nb65_params),y
  sta tftp_ip+1
  iny
  lda (nb65_params),y
  sta tftp_ip+2
  iny
  lda (nb65_params),y
  sta tftp_ip+3

  ldy #NB65_TFTP_FILENAME
  lda (nb65_params),y
  sta tftp_filename
  iny
  lda (nb65_params),y
  sta tftp_filename+1

  ldy #NB65_TFTP_CALL_MODE
  lda (nb65_params),y  
  
  bne @callback_mode  
  ;direct mode
  ldy #NB65_TFTP_POINTER
  lda (nb65_params),y
  sta tftp_load_address
  iny
  lda (nb65_params),y
  sta tftp_load_address+1
  
  jsr tftp_clear_callbacks
  
  clc
  rts
@callback_mode: ;FIXME: callback mode not supported yet
  lda #NB65_ERROR_OPTION_NOT_SUPPORTED
  sta ip65_error
  sec 
  rts

nb65_dispatcher:

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

  cpy #NB65_TFTP_DIRECTORY_LISTING  
  bne :+
  jsr set_tftp_params
  bcs @tftp_error
  jsr tftp_directory_listing

@after_tftp_call:  ;write the current load address back to the param buffer (so if $0000 was passed in, the caller can find out the actual value used)
  bcs @tftp_error
  ldy #NB65_TFTP_POINTER
  lda tftp_load_address
  sta (nb65_params),y  
  iny
  lda tftp_load_address+1
  sta (nb65_params),y  
  clc
@tftp_error:
  rts
:

  cpy #NB65_TFTP_DOWNLOAD
  bne :+
  jsr set_tftp_params
  bcs @tftp_error
  jsr tftp_download
  jmp @after_tftp_call
:

  cpy #NB65_GET_LAST_ERROR
  bne :+
  lda ip65_error
  clc
  rts
:  

;default function handler
  lda #NB65_ERROR_FUNCTION_NOT_SUPPORTED
  sta ip65_error
  sec        ;carry flag set = error
  rts