
#ifndef _LIBNET_H
#define _LIBNET_H


/* IP configuration structure */
typedef unsigned char u8;
typedef unsigned char libnet_err_t;

typedef struct ip_config {
  u8 ip_addr[4];
  u8 netmask[4];
  u8 gateway_addr[4];
  u8 dns_server_addr[4];    
} IP_CONFIG;


#define LIBNET_USE_DHCP 0x0000

extern libnet_err_t __fastcall__ libnet_init (IP_CONFIG* config_p);
extern void __fastcall__ libnet_get_config (IP_CONFIG* config_p);
extern char libnet_MAC[6];




#define LIBNET_OK                           0x00
#define LIBNET_ERROR_PORT_IN_USE                    0x80
#define LIBNET_ERROR_TIMEOUT_ON_RECEIVE             0x81
#define LIBNET_ERROR_TRANSMIT_FAILED                0x82
#define LIBNET_ERROR_TRANSMISSION_REJECTED_BY_PEER  0x83
#define LIBNET_ERROR_INPUT_TOO_LARGE                0x84
#define LIBNET_ERROR_DEVICE_FAILURE                 0x85
#define LIBNET_ERROR_ABORTED_BY_USER                0x86
#define LIBNET_ERROR_LISTENER_NOT_AVAILABLE         0x87
#define LIBNET_ERROR_NO_SUCH_LISTENER               0x88
#define LIBNET_ERROR_CONNECTION_RESET_BY_PEER       0x89
#define LIBNET_ERROR_CONNECTION_CLOSED              0x8A
#define LIBNET_ERROR_TOO_MANY_ERRORS                0x8B
#define LIBNET_ERROR_FILE_ACCESS_FAILURE            0x90
#define LIBNET_ERROR_MALFORMED_URL                  0xA0
#define LIBNET_ERROR_DNS_LOOKUP_FAILED              0xA1
#define LIBNET_ERROR_OPTION_NOT_SUPPORTED           0xFE
#define LIBNET_ERROR_FUNCTION_NOT_SUPPORTED         0xFF


#endif
