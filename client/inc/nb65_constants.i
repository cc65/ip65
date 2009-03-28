
NB65_API_VERSION=$0001

;offsets in NB65 configuration structure
NB65_CFG_MAC        = $00                       ;6 byte MAC address
NB65_CFG_IP         = NB65_CFG_MAC+$06          ;4 byte local IP address (will be overwritten by DHCP)
NB65_CFG_NETMASK    = NB65_CFG_IP+$04           ;4 byte local netmask (will be overwritten by DHCP)
NB65_CFG_GATEWAY    = NB65_CFG_NETMASK+$04      ;4 byte local gateway (will be overwritten by DHCP)
NB65_CFG_DNS_SERVER = NB65_CFG_GATEWAY+$04      ;4 byte IP address of DNS server (will be overwritten by DHCP)
NB65_CFG_TFTP_SERVER = NB65_CFG_DNS_SERVER+$04  ;4 byte IP address of TFTP server (can be broadcast address e.g. 255.255.255.255)
NB65_CFG_DHCP_SERVER = NB65_CFG_TFTP_SERVER+$04 ;4 byte IP address of DHCP server (will only be set by DHCP initialisation)

NB65_GET_API_VERSION      =0 ;no inputs, outputs  X=major version number, A=minor version number
NB65_GET_DRIVER_NAME      =1 ;no inputs, AX=pointer to asciiz driver name
NB65_GET_IP_CONFIG_PTR    =2 ;no inputs, AX=pointer to IP configuration structure (which can be modified)
NB65_INIT_IP              =3 ;no inputs or outputs
NB65_INIT_DHCP            =4 ;no inputs or outputs
