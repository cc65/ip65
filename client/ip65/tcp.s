;TCP (transmission control protocol) functions

.include "../inc/common.i"
.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif

.import ip65_error

.export tcp_init
.export tcp_process
.export tcp_add_listener
.export tcp_remove_listener
.export tcp_send

tcp_add_listener:
tcp_remove_listener:
tcp_send:
tcp_process:
  lda #NB65_ERROR_FUNCTION_NOT_SUPPORTED
  sta ip65_error
  sec
tcp_init:
  rts


.res 2000 ;fixme