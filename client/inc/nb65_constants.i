.ifndef NB65_API_VERSION

NB65_API_VERSION=$0001

;offsets in NB65 configuration structure
NB65_CFG_MAC        = $00                       ;6 byte MAC address
NB65_CFG_IP         = NB65_CFG_MAC+$06          ;4 byte local IP address (will be overwritten by DHCP)
NB65_CFG_NETMASK    = NB65_CFG_IP+$04           ;4 byte local netmask (will be overwritten by DHCP)
NB65_CFG_GATEWAY    = NB65_CFG_NETMASK+$04      ;4 byte local gateway (will be overwritten by DHCP)
NB65_CFG_DNS_SERVER = NB65_CFG_GATEWAY+$04      ;4 byte IP address of DNS server (will be overwritten by DHCP)
NB65_CFG_DHCP_SERVER = NB65_CFG_DNS_SERVER+$04  ;4 byte IP address of DHCP server (will only be set by DHCP initialisation)

;offsets in TFTP paramater structure
NB65_TFTP_CALL_MODE = $00                     ;1 byte for 'mode' : $00 means read/write from RAM, (and TFTP_POINTER is address to read from
                                              ; or write to), any other value means use callbacks (and TFTP_POINTER is the address of a routine
                                              ;to be called whenever data arrives, or needs to be sent)                                              
NB65_TFTP_IP        = $01                     ;4 byte IP address of TFTP server
NB65_TFTP_FILENAME  = $05                     ;2 byte pointer to asciiz filename (or filemask in case of NB65_TFTP_DIRECTORY_LISTING)
NB65_TFTP_POINTER   = $07                     ;2 byte pointer to memory location data to be stored in OR address of tftp callback


;function numbers
NB65_GET_API_VERSION          =$00 ;no inputs, outputs  X=major version number, A=minor version number
NB65_GET_DRIVER_NAME          =$01 ;no inputs, outputs AX=pointer to asciiz driver name
NB65_GET_IP_CONFIG_PTR        =$02 ;no inputs, outputs AX=pointer to IP configuration structure (which can be modified)
NB65_INIT_IP                  =$03 ;no inputs or outputs
NB65_INIT_DHCP                =$04 ;no inputs or outputs (NB65_INIT_IP should be called first, and NB65_VBL_VECTOR should be called @ 60hz)
NB65_TFTP_DIRECTORY_LISTING   =$05 ;inputs: AX points to a TFTP paramater structure, outputs: none
NB65_TFTP_DOWNLOAD            =$06 ;inputs: AX points to a TFTP paramater structure, outputs: TFTP param structure updated with 
                                   ;NB65_TFTP_POINTER updated to reflect actual load address (if load address $0000 originally passed in)

NB65_GET_LAST_ERROR           =$FF ;no inputs, outputs A = error code (from last function that set the global error value, not necessarily the
                                   ;last function that was called)

;error codes (as returned by NB65_GET_LAST_ERROR)
NB65_ERROR_PORT_IN_USE                   = $80
NB65_ERROR_TIMEOUT_ON_RECEIVE            = $81
NB65_ERROR_TRANSMIT_FAILED               = $82
NB65_ERROR_TRANSMISSION_REJECTED_BY_PEER = $83
NB65_ERROR_OPTION_NOT_SUPPORTED          = $FE
NB65_ERROR_FUNCTION_NOT_SUPPORTED        = $FF

.endif