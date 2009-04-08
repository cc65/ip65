.ifndef NB65_API_VERSION

NB65_API_VERSION=$0001


NB65_CART_SIGNATURE             = $8009
NB65_DISPATCH_VECTOR            = $800d 
NB65_PERIODIC_PROCESSING_VECTOR = $8010
NB65_VBL_VECTOR                 = $8013
NB65_RAM_STUB_SIGNATURE         = $C000
NB65_RAM_STUB_ACTIVATE          = $C004

;function numbers
;to make a function call:
; Y = function number
; AX = pointer to parameter buffer (for functions that take parameters)
; then JSR NB65_DISPATCH_VECTOR
; on return, carry flag is set if there is an error, or clear otherwise
; some functions return results in AX directly, others will update the parameter buffer they were called with.
; any register not specified in outputs will have an undefined value on exit

NB65_GET_DRIVER_NAME          =$01 ;no inputs, outputs AX=pointer to asciiz driver name
NB65_GET_IP_CONFIG            =$02 ;AX=pointer to buffer where IP configuration structure written, outputs AX=points to same buffer, which has now been written to
NB65_SET_IP_CONFIG            =$03 ;AX=pointer to buffer where IP configuration structure written, outputs AX=points to same buffer, which has now been written to
NB65_INIT_IP                  =$04 ;no inputs or outputs - also sets IRQ chain to call NB65_VBL_VECTOR at @ 60hz
NB65_INIT_DHCP                =$05 ;no inputs or outputs (NB65_INIT_IP should be called first
NB65_TFTP_DIRECTORY_LISTING   =$06 ;inputs: AX points to a TFTP parameter structure, outputs: none
NB65_TFTP_DOWNLOAD            =$07 ;inputs: AX points to a TFTP parameter structure, outputs: TFTP param structure updated with 
                                   ;NB65_TFTP_POINTER updated to reflect actual load address (if load address $0000 originally passed in)
NB65_DNS_RESOLVE_HOSTNAME     =$08 ;inputs: AX points to a DNS parameter structure, outputs: DNS param structure updated with 
                                   ;NB65_DNS_HOSTNAME_IP updated with IP address corresponding to hostname.
NB65_UDP_ADD_LISTENER         =$09 ;inputs: AX points to a UDP listener parameter structure, outputs: none
NB65_GET_INPUT_PACKET_INFO    =$0A ;inputs: AX points to a UDP packet parameter structure, outputs: UDP packet structure filled in
NB65_SEND_UDP_PACKET          =$0B ;inputs: AX points to a UDP packet parameter structure, outputs: none packet is sent
NB65_UNHOOK_VBL_IRQ           =$0C ;inputs: none, outputs: none (removes call to NB65_VBL_VECTOR on IRQ chain)

NB65_PRINT_ASCIIZ             =$80 ;inputs: AX= pointer to null terminated string to be printed to screen, outputs: none
NB65_PRINT_HEX                =$81 ;inputs: A = byte digit to be displayed on screen as (zero padded) hex digit, outputs: none
NB65_PRINT_DOTTED_QUAD        =$82 ;inputs: AX= pointer to 4 bytes that will be displayed as a decimal dotted quad (e.g. 192.168.1.1)
NB65_PRINT_IP_CONFIG          =$83 ;no inputs, no outputs, prints to screen current IP configuration


NB65_GET_LAST_ERROR           =$FF ;no inputs, outputs A = error code (from last function that set the global error value, not necessarily the
                                   ;last function that was called)

;offsets in NB65 configuration structure
NB65_CFG_MAC        = $00     ;6 byte MAC address
NB65_CFG_IP         = $06     ;4 byte local IP address (will be overwritten by DHCP)
NB65_CFG_NETMASK    = $0A     ;4 byte local netmask (will be overwritten by DHCP)
NB65_CFG_GATEWAY    = $0D     ;4 byte local gateway (will be overwritten by DHCP)
NB65_CFG_DNS_SERVER = $12     ;4 byte IP address of DNS server (will be overwritten by DHCP)
NB65_CFG_DHCP_SERVER = $16    ;4 byte IP address of DHCP server (will only be set by DHCP initialisation)

;offsets in TFTP parameter structure
NB65_TFTP_IP        = $00                     ;4 byte IP address of TFTP server
NB65_TFTP_FILENAME  = $04                     ;2 byte pointer to asciiz filename (or filemask in case of NB65_TFTP_DIRECTORY_LISTING)
NB65_TFTP_POINTER   = $06                     ;2 byte pointer to memory location data to be stored in OR address of tftp callback

;offsets in TFTP parameter structure
NB65_DNS_HOSTNAME   = $00                         ;2 byte pointer to asciiz hostname to resolve (can also be a dotted quad string)
NB65_DNS_HOSTNAME_IP= $00                         ;4 byte IP address (filled in on succesful resolution of hostname)

;offsets in UDP listener parameter structure
NB65_UDP_LISTENER_PORT     = $00                       ;2 byte port number
NB65_UDP_LISTENER_CALLBACK = $02                       ;2 byte address of routine to call when UDP packet arrives for specified port

;offsets in UDP packet parameter structure
NB65_REMOTE_IP      = $00                          ;4 byte IP address of remote machine (src of inbound packets, dest of outbound packets)
NB65_REMOTE_PORT    = $04                          ;2 byte port number of remote machine (src of inbound packets, dest of outbound packets)
NB65_LOCAL_PORT     = $06                          ;2 byte port number of local machine (src of outbound packets, dest of inbound packets)
NB65_PAYLOAD_LENGTH = $08                          ;2 byte length of payload of packet (after all ethernet,IP,UDP headers)
NB65_PAYLOAD_POINTER =$0A                          ;2 byte pointer to payload of packet (after all headers)

;error codes (as returned by NB65_GET_LAST_ERROR)
NB65_ERROR_PORT_IN_USE                   = $80
NB65_ERROR_TIMEOUT_ON_RECEIVE            = $81
NB65_ERROR_TRANSMIT_FAILED               = $82
NB65_ERROR_TRANSMISSION_REJECTED_BY_PEER = $83
NB65_ERROR_INPUT_TOO_LARGE               = $84
NB65_ERROR_OPTION_NOT_SUPPORTED          = $FE
NB65_ERROR_FUNCTION_NOT_SUPPORTED        = $FF

.endif