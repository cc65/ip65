; RR-Net driver


	.export cs_init

	.export cs_packet_page
	.export cs_packet_data
	.export cs_rxtx_data
	.export cs_tx_cmd
	.export cs_tx_len
  .export cs_driver_name

rr_ctl		= $de01

;cs_irq		= $de00
cs_packet_page	= $de02
cs_packet_data	= $de04
;cs_packet_data2	= $de06
cs_rxtx_data	= $de08
;cs_rxtx_data2	= $de0a
cs_tx_cmd	= $de0c
cs_tx_len	= $de0e


	.code

cs_init:
	lda rr_ctl
	ora #1
	sta rr_ctl
	rts

cs_driver_name:
	.asciiz "RR-NET"
