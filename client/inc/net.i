	.import ip65_init
	.import ip65_process
  
  .import cfg_mac
  .import cfg_ip
  .import cfg_netmask
  .import cfg_gateway
  .import cfg_dns
  .import cfg_tftp_server
  
  .import dhcp_init
  .import dhcp_server
  

.macro init_ip_via_dhcp

  print_driver_init
  jsr ip65_init
	bcc :+
  print_failed
  sec
  jmp @end_macro
    
:
  
  print_ok
  
  print_dhcp_init
  
  jsr dhcp_init
	bcc :+

  
	print_failed
  sec
	rts
:
  print_ok
  clc
@end_macro:
.endmacro