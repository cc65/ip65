#ifndef _IP65_H
#define _IP65_H

// Error codes
//
#define IP65_ERROR_PORT_IN_USE                   $80
#define IP65_ERROR_TIMEOUT_ON_RECEIVE            $81
#define IP65_ERROR_TRANSMIT_FAILED               $82
#define IP65_ERROR_TRANSMISSION_REJECTED_BY_PEER $83
#define IP65_ERROR_INPUT_TOO_LARGE               $84
#define IP65_ERROR_DEVICE_FAILURE                $85
#define IP65_ERROR_ABORTED_BY_USER               $86
#define IP65_ERROR_LISTENER_NOT_AVAILABLE        $87
#define IP65_ERROR_CONNECTION_RESET_BY_PEER      $89
#define IP65_ERROR_CONNECTION_CLOSED             $8A
#define IP65_ERROR_FILE_ACCESS_FAILURE           $90
#define IP65_ERROR_MALFORMED_URL                 $A0
#define IP65_ERROR_DNS_LOOKUP_FAILED             $A1

// Last error code
//
extern unsigned char ip65_error;

// MAC address of local machine (will be overwritten if ip65_init is called)
//
extern unsigned char cfg_mac[6];

// IP address of local machine (will be overwritten if dhcp_init is called)
//
extern unsigned long cfg_ip;

// Netmask of local network (will be overwritten if dhcp_init is called)
//
extern unsigned long cfg_netmask;

// IP address of router on local network (will be overwritten if dhcp_init is called)
//
extern unsigned long cfg_gateway;

// IP address of dns server to use (will be overwritten if dhcp_init is called)
//
extern unsigned long cfg_dns;

// Will be set to address of DHCP server that configuration was obtained from
//
extern unsigned long dhcp_server;

//
//
extern unsigned char* tcp_packet;
extern unsigned int   tcp_packet_len;

// Initialise the IP stack
//
// This calls the individual protocol & driver initialisations, so this is
// the only *_init routine that must be called by a user application,
// except for dhcp_init which must also be called if the application
// is using DHCP rather than hardcoded IP configuration.
//
// Inputs: None
// Output: 1 if there was an error, 0 otherwise
//
unsigned char ip65_init(void);

// Main IP polling loop
//
// This routine should be periodically called by an application at any time
// that an inbound packet needs to be handled.
// It is 'non-blocking', i.e. it will return if there is no packet waiting to be
// handled. Any inbound packet will be handed off to the appropriate handler.
//
// Inputs: None
// Output: 1 if no packet was waiting or packet handling caused error, 0 otherwise
//
unsigned char ip65_process(void);

// Generate a 'random' 16 bit word
//
// Entropy comes from the last ethernet frame, counters, and timer.
//
// Inputs: None
// Output: Pseudo-random 16 bit number
//
unsigned int ip65_random_word(void);

// Convert 4 octets (IP address, netmask) into a string representing a dotted quad
//
// The string is returned in a statically allocated buffer, which subsequent calls
// will overwrite.
//
// Inputs: quad: IP address
// Output: Null terminated string containing dotted quad (e.g. "192.168.1.0")
//
char* __fastcall__ dotted_quad(unsigned long quad);

// Convert a string representing a dotted quad (IP address, netmask) into 4 octets
//
// Inputs: quad: Null terminated string containing dotted quad (e.g. "192.168.1.0"),
//               to simplify URL parsing, a ':' or '/' can also terminate the string.
// Output: IP address, 0 on error
//
unsigned long __fastcall__ parse_dotted_quad(char* quad);

// Minimal DHCP client implementation
//
// IP addresses are requested from a DHCP server (aka 'leased') but are not renewed
// or released. Although this is not correct behaviour according to  the DHCP RFC,
// this works fine in practice in a typical home network environment.
//
// Inputs: None (although ip65_init should be called first)
// Output: 0 if IP config has been sucesfully obtained and cfg_ip, cfg_netmask,
//           cfg_gateway and cfg_dns will be set per response from dhcp server.
//           dhcp_server will be set to address of server that provided configuration.
//         1 if there was an error
//
unsigned char dhcp_init(void);

// Resolve a string containing a hostname (or a dotted quad) to an IP address
//
// Inputs: hostname: pointer to null terminated string that contains either
//                   a DNS hostname (e.g. "host.example.com") or an address
//                   in "dotted quad" format (e.g. "192.168.1.0").
// Output: IP address of the hostname, 0 on error
//
unsigned long __fastcall__ dns_resolve(const char* hostname);

// Send a ping (ICMP echo request) to a remote host, and wait for a response
//
// Inputs: dest: Destination IP address
// Output: 0 if no response, otherwise time (in miliseconds) for host to respond
//
unsigned int __fastcall__ icmp_ping(unsigned long dest);

// Add a UDP listener
//
// Inputs: port:     UDP port to listen on
//         callback: Vector to call when UDP packet arrives on specified port
// Output: 1 if too may listeners already installed, 0 otherwise
//
unsigned char __fastcall__ udp_add_listener(unsigned int port, void (*callback)(void));

// Remove a UDP listener
//
// Inputs: port: UDP port to stop listening on
// Output: 0 if handler found and removed,
//         1 if handler for specified port not found
//
unsigned char __fastcall__ udp_remove_listener(unsigned int port);

// Access to received UDP packet
//
// Access to the four items below is only valid in the context of a callback
// added with udp_add_listener.
//
extern unsigned char udp_recv_buf[1476];        // Buffer with data received
       unsigned int  udp_recv_len(void);        // Length of data received
       unsigned long udp_recv_src(void);        // Source IP address
       unsigned int  udp_recv_src_port(void);   // Source port

// Send a UDP packet
//
// If the correct MAC address can't be found in the ARP cache then
// an ARP request is sent - and the UDP packet is NOT sent. The caller
// should wait a while calling ip65_process (to allow time for an ARP
// response to arrive) and then call upd_send again. This behavior
// makes sense as a UDP packet may get lost in transit at any time
// so the caller should to be prepared to resend it after a while
// anyway.
//
// Inputs: buf:       Pointer to buffer containing data to be sent
//         len:       Length of data to send (exclusive of any headers)
//         dest:      Destination IP address
//         dest_port: Destination port
//         src_port:  Source port
// Output: 1 if an error occured, 0 otherwise
//
unsigned char __fastcall__ udp_send(const unsigned char* buf, unsigned int len,
                                    unsigned long dest, unsigned int dest_port,
                                    unsigned int src_port);

#endif
