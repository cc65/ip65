; RR-Net driver


	.export cs_init

	.export cs_packet_page
	.export cs_packet_data
	.export cs_rxtx_data
	.export cs_tx_cmd
	.export cs_tx_len
  .export cs_driver_name

rr_ctl		= $de01 ;address of 'control' port on Retro-Replay
cs_packet_page	= $de02 ;address of 'packet page' port on RR-Net
cs_packet_data	= $de04;address of 'packet data' port on RR-Net
cs_rxtx_data	= $de08 ;address of 'recieve/transmit data' port on RR-Net
cs_tx_cmd	= $de0c;address of 'transmit command' port on RR-Net
cs_tx_len	= $de0e;address of 'transmission length' port on RR-Net


.code

;initialise Retro Replay so we can access the network adapter
;inputs: none
;outputs: none
cs_init:
	lda rr_ctl
	ora #1
	sta rr_ctl
	rts

.rodata
cs_driver_name:
	.asciiz "RR-NET"
