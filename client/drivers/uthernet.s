;uthernet driver
;currently hardcoded to use slot 3 addresses only


	.export cs_init

	.export cs_packet_page
	.export cs_packet_data
	.export cs_rxtx_data
	.export cs_tx_cmd
	.export cs_tx_len
  .export cs_driver_name
  
cs_rxtx_data	= $c0b0 ;address of 'recieve/transmit data' port on Uthernet
cs_tx_cmd	= $c0b4;address of 'transmit command' port on Uthernet
cs_tx_len	= $c0b6;address of 'transmission length' port on Uthernet
cs_packet_page	= $c0ba;address of 'packet page' port on Uthernet
cs_packet_data	= $c0bc;address of 'packet data' port on Uthernet
 

	.code

cs_init:
	
	rts

.rodata
cs_driver_name:
	.byte "UTHERNET",0