;IP configuration defaults
;most of these will be overwritten if dhcp is used for configuration

	.export cfg_mac
	.export cfg_ip
	.export cfg_netmask
	.export cfg_gateway
	.export cfg_dns
  .export cfg_tftp_server
  
.data	

cfg_mac:	.byte $00, $80, $10, $6d, $76, $30  ;mac address to be assigned to local machine
;cfg_ip:		.byte 192, 168, 0, 64

cfg_ip:		.byte 0,0,0,0 ;ip address of local machine (will be overwritten if dhcp_init is called)
cfg_netmask:	.byte 255, 255, 255, 0; netmask of local network (will be overwritten if dhcp_init is called)
cfg_gateway:	.byte 0, 0, 0, 0 ;ip address of router on local network (will be overwritten if dhcp_init is called)
cfg_dns:	.byte 0, 0, 0, 0; ip address of dns server to use (will be overwritten if dhcp_init is called)
cfg_tftp_server: .byte $ff,$ff,$ff,$ff ; ip address of server to send tftp requests to (can be a broadcast address)
  