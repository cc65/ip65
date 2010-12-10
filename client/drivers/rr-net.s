; RR-Net driver


	.export cs_init

	.export cs_packet_page
	.export cs_packet_data
	.export cs_rxtx_data
	.export cs_tx_cmd
	.export cs_tx_len
  .export eth_driver_name

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
eth_driver_name:
	.asciiz "RR-NET"



;-- LICENSE FOR rr-net.s --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
; 
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
; 
; The Original Code is ip65.
; 
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
