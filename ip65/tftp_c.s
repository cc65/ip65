.include "../inc/common.inc"

.export _tftp_download
.export _tftp_download_to_memory
.export _tftp_upload
.export _tftp_upload_from_memory

.import tftp_download
.import tftp_upload
.import tftp_upload_from_memory
.import tftp_set_callback_vector
.import tftp_clear_callbacks
.import tftp_ip
.import tftp_load_address
.import tftp_data_block_length
.import tftp_current_memloc
.import tftp_filename
.import tftp_filesize

.import pushax, popax, popeax
.importzp sreg


.data

callback:
  clc
  adc #02                       ; skip the 2 byte length at start of buffer
  bcc :+
  inx
: jsr pushax
  ldax tftp_data_block_length
jmpvector:
  jmp $ffff


.code

_tftp_download:
  stax jmpvector+1
  ldax #callback
  jsr tftp_set_callback_vector
  jsr popax
  stax tftp_filename
  jsr popeax
  stax tftp_ip
  ldax sreg
  stax tftp_ip+2
  jsr tftp_download
  ldx #$00
  txa
  rol
  rts

_tftp_download_to_memory:
  stax tftp_load_address
  jsr tftp_clear_callbacks
  jsr popax
  stax tftp_filename
  jsr popeax
  stax tftp_ip
  ldax sreg
  stax tftp_ip+2
  jsr tftp_download
  bcs error
  sec
  lda tftp_current_memloc
  sbc tftp_load_address
  tay
  lda tftp_current_memloc+1
  sbc tftp_load_address+1
  tax
  tya
  rts

error:
  ldx #$00
  txa
  rts

_tftp_upload:
  jsr tftp_set_callback_vector
  jsr popax
  stax tftp_filename
  jsr popeax
  stax tftp_ip
  ldax sreg
  stax tftp_ip+2
  jsr tftp_upload
  ldx #$00
  txa
  rol
  rts

_tftp_upload_from_memory:
  stax tftp_filesize
  jsr popax
  stax tftp_load_address
  jsr popax
  stax tftp_filename
  jsr popeax
  stax tftp_ip
  ldax sreg
  stax tftp_ip+2
  jsr tftp_upload_from_memory
  ldx #$00
  txa
  rol
  rts
