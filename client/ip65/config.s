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
  .export cfg_init
  .export dhcp_server 
  .import copymem
  .importzp copy_src
  .importzp copy_dest
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

;copy the IP stack defaults (probably stored in ROM) to the running values in RAM
;inputs: none
;outputs: AX = pointer to IP configuration.
cfg_init:  
  ldax  #cfg_mac_default
  stax copy_src
  ldax  #cfg_mac
  stax copy_dest
  ldax  #cfg_size
  jmp copymem

.segment "IP65_DEFAULTS"
cfg_mac_default:	.byte $00, $80, $10, $6d, $76, $30  ;mac address to be assigned to local machine
;cfg_ip_default:		.byte 192, 168, 1, 64 ;ip address of local machine (will be overwritten if dhcp_init is called)
cfg_ip_default:		.byte 0,0,0,0 ;ip address of local machine (will be overwritten if dhcp_init is called)
cfg_netmask_default:	.byte 255, 255, 255, 0; netmask of local network (will be overwritten if dhcp_init is called)
cfg_gateway_default:	.byte 0, 0, 0, 0 ;ip address of router on local network (will be overwritten if dhcp_init is called)
;cfg_gateway_default:	.byte 192, 168, 1, 1 ;ip address of router on local network (will be overwritten if dhcp_init is called)
cfg_dns_default:	.byte 0, 0, 0, 0; ip address of dns server to use (will be overwritten if dhcp_init is called)
dhcp_server_default: .res 4   ;will be set address of dhcp server that configuration was obtained from
cfg_tftp_server_default: .byte $ff,$ff,$ff,$ff ; ip address of server to send tftp requests to (can be a broadcast address)
cfg_end_defaults:
cfg_size=cfg_end_defaults-cfg_mac_default+1


.bss

cfg_mac:	.res 6  ;mac address to be assigned to local machine
cfg_ip:		.res 4 ;ip address of local machine (will be overwritten if dhcp_init is called)
cfg_netmask:	.res 4, 0; netmask of local network (will be overwritten if dhcp_init is called)
cfg_gateway:	.res 4 ;ip address of router on local network (will be overwritten if dhcp_init is called)
cfg_dns:	.res 4; ip address of dns server to use (will be overwritten if dhcp_init is called)
dhcp_server: .res 4   ;will be set address of dhcp server that configuration was obtained from
cfg_tftp_server: .res 4 ; ip address of server to send tftp requests to (can be a broadcast address)

