;constants for accessing the NB65 API file
;to use this file under CA65, then add "  .define EQU     =" to your code before this file is included.


NB65_API_VERSION_NUMBER  EQU $02


NB65_CART_SIGNATURE              EQU $8009
NB65_API_VERSION                 EQU $800d
NB65_BANKSWITCH_SUPPORT          EQU $800e
NB65_DISPATCH_VECTOR             EQU $800f 
NB65_PERIODIC_PROCESSING_VECTOR  EQU $8012
NB65_VBL_VECTOR                  EQU $8015
NB65_RAM_STUB_SIGNATURE          EQU $C000
NB65_RAM_STUB_ACTIVATE           EQU $C004

;function numbers
;to make a function call:
; Y  EQU function number
; AX  EQU pointer to parameter buffer (for functions that take parameters)
; then JSR NB65_DISPATCH_VECTOR
; on return, carry flag is set if there is an error, or clear otherwise
; some functions return results in AX directly, others will update the parameter buffer they were called with.
; any register not specified in outputs will have an undefined value on exit

NB65_INITIALIZE                EQU $01 ;no inputs or outputs - initializes IP stack, also sets IRQ chain to call NB65_VBL_VECTOR at @ 60hz
NB65_GET_IP_CONFIG             EQU $02 ;no inputs, outputs AX=pointer to IP configuration structure
NB65_DEACTIVATE                EQU $0F ;inputs: none, outputs: none (removes call to NB65_VBL_VECTOR on IRQ chain)

NB65_UDP_ADD_LISTENER          EQU $10 ;inputs: AX points to a UDP listener parameter structure, outputs: none
NB65_GET_INPUT_PACKET_INFO     EQU $11 ;inputs: AX points to a UDP/TCP packet parameter structure, outputs: UDP/TCP packet structure filled in
NB65_SEND_UDP_PACKET           EQU $12 ;inputs: AX points to a UDP packet parameter structure, outputs: none packet is sent
NB65_UDP_REMOVE_LISTENER       EQU $13 ;inputs: AX contains UDP port number that listener will be removed from

NB65_TCP_CONNECT               EQU $14 ;inputs: AX points to a TCP connect parameter structure, outputs: none
NB65_SEND_TCP_PACKET           EQU $15 ;inputs: AX points to a TCP send parameter structure, outputs: none packet is sent
NB65_TCP_CLOSE_CONNECTION      EQU $16 ;inputs: none outputs: none

NB65_TFTP_SET_SERVER           EQU $20 ;inputs: AX points to a TFTP server parameter structure, outputs: none
NB65_TFTP_DOWNLOAD             EQU $22 ;inputs: AX points to a TFTP transfer parameter structure, outputs: TFTP param structure updated with 
                                       ;NB65_TFTP_POINTER updated to reflect actual load address (if load address $0000 originally passed in)
NB65_TFTP_CALLBACK_DOWNLOAD    EQU $23 ;inputs: AX points to a TFTP transfer parameter structure, outputs: none
NB65_TFTP_UPLOAD               EQU $24 ;upload: AX points to a TFTP transfer parameter structure, outputs: none
NB65_TFTP_CALLBACK_UPLOAD      EQU $25 ;upload: AX points to a TFTP transfer parameter structure, outputs: none

NB65_DNS_RESOLVE               EQU $30 ;inputs: AX points to a DNS parameter structure, outputs: DNS param structure updated with 
                                   ;NB65_DNS_HOSTNAME_IP updated with IP address corresponding to hostname.


NB65_PRINT_ASCIIZ              EQU $80 ;inputs: AX=pointer to null terminated string to be printed to screen, outputs: none
NB65_PRINT_HEX                 EQU $81 ;inputs: A=byte digit to be displayed on screen as (zero padded) hex digit, outputs: none
NB65_PRINT_DOTTED_QUAD         EQU $82 ;inputs: AX=pointer to 4 bytes that will be displayed as a decimal dotted quad (e.g. 192.168.1.1)
NB65_PRINT_IP_CONFIG           EQU $83 ;no inputs, no outputs, prints to screen current IP configuration


NB65_INPUT_STRING              EQU $90 ;no inputs, outputs: AX = pointer to null terminated string
NB65_INPUT_HOSTNAME            EQU $91 ;no inputs, outputs: AX = pointer to hostname (which may be IP address).
NB65_INPUT_PORT_NUMBER         EQU $92 ;no inputs, outputs: AX = port number entered ($0000..$FFFF)

NB65_BLOCK_COPY                EQU $A0 ;inputs: AX points to a block copy structure, outputs: none

NB65_GET_LAST_ERROR            EQU $FF ;no inputs, outputs A  EQU error code (from last function that set the global error value, not necessarily the
                                   ;last function that was called)

;offsets in IP configuration structure (used by NB65_GET_IP_CONFIG)
NB65_CFG_MAC         EQU $00     ;6 byte MAC address
NB65_CFG_IP          EQU $06     ;4 byte local IP address (will be overwritten by DHCP)
NB65_CFG_NETMASK     EQU $0A     ;4 byte local netmask (will be overwritten by DHCP)
NB65_CFG_GATEWAY     EQU $0E     ;4 byte local gateway (will be overwritten by DHCP)
NB65_CFG_DNS_SERVER  EQU $12     ;4 byte IP address of DNS server (will be overwritten by DHCP)
NB65_CFG_DHCP_SERVER EQU $16    ;4 byte IP address of DHCP server (will only be set by DHCP initialisation)
NB65_DRIVER_NAME     EQU $1A     ;2 byte pointer to name of driver

;offsets in TFTP transfer parameter structure (used by NB65_TFTP_DOWNLOAD, NB65_TFTP_CALLBACK_DOWNLOAD,  NB65_TFTP_UPLOAD, NB65_TFTP_CALLBACK_UPLOAD)
NB65_TFTP_FILENAME   EQU $00                     ;2 byte pointer to asciiz filename (or filemask)
NB65_TFTP_POINTER    EQU $02                     ;2 byte pointer to memory location data to be stored in OR address of callback function
NB65_TFTP_FILESIZE   EQU $04                     ;2 byte file length (filled in by NB65_TFTP_DOWNLOAD, must be passed in to NB65_TFTP_UPLOAD)

;offsets in TFTP Server parameter structure (used by NB65_TFTP_SET_SERVER)
NB65_TFTP_SERVER_IP  EQU $00                     ;4 byte IP address of TFTP server

;offsets in DNS parameter structure (used by NB65_DNS_RESOLVE)
NB65_DNS_HOSTNAME    EQU $00                         ;2 byte pointer to asciiz hostname to resolve (can also be a dotted quad string)
NB65_DNS_HOSTNAME_IP EQU $00                         ;4 byte IP address (filled in on succesful resolution of hostname)

;offsets in UDP listener parameter structure
NB65_UDP_LISTENER_PORT      EQU $00                       ;2 byte port number
NB65_UDP_LISTENER_CALLBACK  EQU $02                       ;2 byte address of routine to call when UDP packet arrives for specified port

;offsets in block copy  parameter structure
NB65_BLOCK_SRC            EQU $00                   ;2 byte address of start of source block
NB65_BLOCK_DEST           EQU $02                   ;2 byte address of start of destination block
NB65_BLOCK_SIZE           EQU $04                   ;2 byte length of block to be copied (in bytes


;offsets in TCP connect parameter structure
NB65_TCP_REMOTE_IP      EQU $00                       ;4 byte IP address of remote host (0.0.0.0 means wait for inbound i.e. server mode)
NB65_TCP_PORT           EQU $04                       ;2 byte port number (to listen on, if ip address was 0.0.0.0, or connect to otherwise)
NB65_TCP_CALLBACK       EQU $06                       ;2 byte address of routine to be called whenever a new packet arrives

;offsets in TCP send parameter structure
NB65_TCP_PAYLOAD_LENGTH         EQU $00               ;2 byte length of payload of packet (after all ethernet,IP,UDP/TCP headers)
NB65_TCP_PAYLOAD_POINTER        EQU $02               ;2 byte pointer to payload of packet (after all headers)

;offsets in TCP/UDP packet parameter structure
NB65_REMOTE_IP       EQU $00                          ;4 byte IP address of remote machine (src of inbound packets, dest of outbound packets)
NB65_REMOTE_PORT     EQU $04                          ;2 byte port number of remote machine (src of inbound packets, dest of outbound packets)
NB65_LOCAL_PORT      EQU $06                          ;2 byte port number of local machine (src of outbound packets, dest of inbound packets)
NB65_PAYLOAD_LENGTH  EQU $08                          ;2 byte length of payload of packet (after all ethernet,IP,UDP/TCP headers)
                                                      ; in a TCP connection, if the length is $FFFF, this actually means "end of connection"
NB65_PAYLOAD_POINTER EQU $0A                          ;2 byte pointer to payload of packet (after all headers)

;error codes (as returned by NB65_GET_LAST_ERROR)
NB65_ERROR_PORT_IN_USE                    EQU $80
NB65_ERROR_TIMEOUT_ON_RECEIVE             EQU $81
NB65_ERROR_TRANSMIT_FAILED                EQU $82
NB65_ERROR_TRANSMISSION_REJECTED_BY_PEER  EQU $83
NB65_ERROR_INPUT_TOO_LARGE                EQU $84
NB65_ERROR_DEVICE_FAILURE                 EQU $85
NB65_ERROR_ABORTED_BY_USER                EQU $86
NB65_ERROR_LISTENER_NOT_AVAILABLE         EQU $87
NB65_ERROR_NO_SUCH_LISTENER               EQU $88
NB65_ERROR_CONNECTION_RESET_BY_PEER       EQU $89
NB65_ERROR_CONNECTION_CLOSED              EQU $8A
NB65_ERROR_OPTION_NOT_SUPPORTED           EQU $FE
NB65_ERROR_FUNCTION_NOT_SUPPORTED         EQU $FF
