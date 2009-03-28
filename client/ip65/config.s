;IP configuration defaults
;most of these will be overwritten if dhcp is used for configuration

.include "../inc/common.i"

	.export cfg_mac
	.export cfg_ip
	.export cfg_netmask
	.export cfg_gateway
	.export cfg_dns
  .export cfg_tftp_server
  .export cfg_get_configuration_ptr
  .export dhcp_server 
  
.code

;return a pointer to where the IP configuration is kept
;this is really only useful for the NB65 API - for anything
;linking directly against ip65, you would just import the
;address of the individual configuration elements, rather
;than use a base pointer+offsets to find each item.
;inputs: none
;outputs: AX = pointer to IP configuration.
cfg_get_configuration_ptr:  
  ldax  #cfg_mac
  clc
  rts
  
.data	

cfg_mac:	.byte $00, $80, $10, $6d, $76, $30  ;mac address to be assigned to local machine
;cfg_ip:		.byte 192, 168, 0, 64

cfg_ip:		.byte 0,0,0,0 ;ip address of local machine (will be overwritten if dhcp_init is called)
cfg_netmask:	.byte 255, 255, 255, 0; netmask of local network (will be overwritten if dhcp_init is called)
cfg_gateway:	.byte 0, 0, 0, 0 ;ip address of router on local network (will be overwritten if dhcp_init is called)
cfg_dns:	.byte 0, 0, 0, 0; ip address of dns server to use (will be overwritten if dhcp_init is called)
cfg_tftp_server: .byte $ff,$ff,$ff,$ff ; ip address of server to send tftp requests to (can be a broadcast address)
dhcp_server: .res 4   ;will be set address of dhcp server that configuration was obtained from