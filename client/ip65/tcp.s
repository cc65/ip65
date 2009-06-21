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


.segment "TCP_VARS"
tcp_cxn_state       =0
tcp_cxn_local_port  =1
tcp_cxn_remote_port =3
tcp_cxn_remote_ip   =5
tcp_cxn_local_seq   =9
tcp_cxn_remote_seq  =13

tcp_cxn_entry_size  =17
tcp_max_connections =10

tcp_connections:
  .res  tcp_max_connections*tcp_cxn_entry_size
.code
tcp_add_listener:
tcp_remove_listener:
tcp_send:
tcp_process:
  lda #NB65_ERROR_FUNCTION_NOT_SUPPORTED
  sta ip65_error
  sec
tcp_init:
  rts


