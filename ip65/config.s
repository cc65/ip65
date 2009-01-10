;originally from Per Olofsson's IP65 library - http://www.paradroid.net/ip65

; Configuration


	.export cfg_mac
	.export cfg_ip
	.export cfg_netmask
	.export cfg_gateway
	.export cfg_dns
  .export cfg_tftp_server
  
.data	; these are defaults 

cfg_mac:	.byte $00, $80, $10, $6d, $76, $30
;cfg_ip:		.byte 192, 168, 0, 64
cfg_ip:		.byte 0,0,0,0
cfg_netmask:	.byte 255, 255, 255, 0
cfg_gateway:	.byte 0, 0, 0, 0
cfg_dns:	.byte 0, 0, 0, 0
cfg_tftp_server: .byte $ff,$ff,$ff,$ff 