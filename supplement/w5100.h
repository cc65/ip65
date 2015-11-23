/******************************************************************************

Copyright (c) 2014, Oliver Schmidt
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL OLIVER SCHMIDT BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

******************************************************************************/


/******************************************************************************

Some notes by Oliver Schmidt on the WIZnet W5100 Ethernet controller:

1. Operation Modes

1.1 MAC-Raw
In MAC-Raw mode the W5100 behaves pretty much like a CS8900A or a LAN91C96. The
W5100 is usually only configured with a MAC address which is used by the W5100
to limit incoming frames to those sent to its MAC address (or broadcasts).

1.2 IP-Raw
IP-Raw mode is usable to implement non-UDP/non-TCP IP protocols like ICMP. The
W5100 is usually configured with a full IP profile (IP addr, netmask, gateway).
It transparently takes care of incoming/outgoing ARP and optionally of incoming
ICMP Echo (aka Ping).

1.3 UDP
UDP mode is pretty simlar to IP-Raw mode but additionally takes care of header
checksum calculation.

1.4 TCP
TCP mode is rather different from the other modes. Incoming/outgoing data isn't
delimited by headers like in all other modes. Rather the W5100 behaves like a
BSD socket delivering/taking a data stream - in chunks not necessarily related
to data packets received/sent. The W5100 transparently takes care of TCP flow
control by sending ACK packets. It advertises a receive window identical to the
free space in the its receive memory buffer.

The W5100 offers up to 4 'sockets' allowing to specify the operation mode for
each socket individually. However MAC-Raw mode is only available for the first
socket. It is possible to combine MAC-Raw mode with other modes for the other
sockets - which is called 'hybrid TCP/IP stack'. I have no personal experience
with this hybrid TCP/IP stack and see open questions:
- Are packets delivered to other sockets filtered from the first socket?
- Who takes care of incoming ARP and incoming ICMP Echo?

The W5100 divides its 16kB memory buffer statically into 8kB for receive and
8kB for send (in contrast to the CS8900A and the LAN91C96 which both do dynamic
receive/send buffer division). When using several sockets it is additionally
necessary to statically assign the two 8kB memory buffers to the sockets.

2. Memory Buffer Access
In 6502 machines the W5100 is accessed using its indirect bus interface. This
interface optionally allows for pointer auto-increment (like the CS8900A and
the LAN91C96). However in contrast to those two Ethernet controllers the W5100
does NOT virtualize access to its memory buffer! So when reading/writing data
from/to the W5100 and reaching the end of the memory buffer assigned to the
socket it's the responsibility of the 6502 program to continue reading/writing
at the begin of the memory buffer. Please note that the pointer auto-increment
does NOT take care of that wraparound operation! I have implemented several
ways to handle this difficulty.

2.1 Copy Split
If it is necessary or desired to have the interface to the upper layers being
based on a receive/send buffer and one can afford the memory for a little more
code than it is appropriate to check in advance if receive/send will require a
wraparound and in that case split the copy from/to the buffer into two copy
operations. That approach is used in all WIZnet code and I implemented it in
pretty optimized 6502 code for the Contiki/IP65 MAC-Raw mode driver located in
drivers/w5100.s - however the copy split technique is in general applicable to
all W5100 operation modes.

2.2 Shadow Register
When it comes to using as little memory as possible I consider it in general
questionable if a buffer is the right interface paradigm. In many scenarios it
makes more sense to read/write bytes individually. This allows i.e. to directly
write bytes from individual already existing data structures to the W5100 or
analyze bytes directly on reading from the W5100 to decide on processing of
subsequent bytes - and maybe ignore them altogether. This approach splits a
receive/send operation into three phases: The initialization, the individual
byte read/write and the finalization. The initialization sets up a 16-bit
shadow register to be as far away from overflow as the auto-increment pointer
is away from the necessary wraparound. The individual byte read/write then
increments the shadow register and on its overflow resets the auto-increment
pointer to the begin of the memory buffer. I implemented this approach in two
drivers using heavily size-optimized 6502 code for the W5100 UDP mode and TCP
mode showing that the shadow register technique yields the smallest code. They
are located in supplement/w5100_udp.s and supplement/w5100_tcp.s with C test
programs located in test/w5100_udp_main.c and test/w5100_tcp_main.c. There's a
Win32 communication peer for the test programs located in test/w5100_peer.c.

2.3 TCP Stream Split
A correct BSD TCP socket program never presumes to be able to read/write any
amount of data. Rather it is always prepared to call recv()/send() as often as
necessary to receive/send the expected amount data in whatever chunks - and the
very same holds true for any program using the W5100 TCP mode! But this already
necessary complexity in the upper layers allows to handle W5100 memory buffer
wraparounds transparently by artificially limiting the size of a read/write
operation to the end of the memory buffer if necessary. The next read/write
operation then works with the begin of the memory buffer. This approach shares
the benefits of the shadow register technique while avoiding its performance
penalties coming from maintaining the shadow register. Additionally it allows
the upper layers to directly access the auto-increment W5100 data register for
individual byte read/write because it is known to stay within the memory buffer
limits. Therefore the TCP stream split technique avoids both the overhead of a
buffer as well as the overhead of function calls for individual bytes. It sort
of combines the best of both sides but it means larger code than the shadow
register technique and is only applicable to the W5100 TCP mode. I implemented
the TCP stream split technique in a C-only driver located in supplement/w5100.c
with a test program representing the upper layers located in test/w5100_main.c
being compatible with test/w5100_peer.c.

******************************************************************************/

#ifndef _W5100_H_
#define _W5100_H_

typedef unsigned char  byte;
typedef unsigned short word;

word w5100_data_request(byte do_send);
void w5100_data_commit(byte do_send, word size);

// After w5100_receive_request() every read operation returns the next byte
// from the server.
// After w5100_send_request() every write operation prepares the next byte
// to be sent to the server.
extern volatile byte* w5100_data;

// Initialize W5100 Ethernet controller with indirect bus interface located
// at <base_addr>. Use <ip_addr>, <submask> and <gateway> to configure the
// TCP/IP stack.
// Return <1> if a W5100 was found at <base_addr>, return <0> otherwise.
byte w5100_init(word base_addr, byte *ip_addr,
                                byte *submask,
                                byte *gateway);

// Connect to server with IP address <server_addr> on TCP port <server_port>.
// Use <6502> as fixed local port.
// Return <1> if the connection is established, return <0> otherwise.
byte w5100_connect(byte *server_addr, word server_port);

// Check if still connected to server.
// Return <1> if the connection is established, return <0> otherwise.
byte w5100_connected(void);

// Disconnect from server.
void w5100_disconnect(void);

// Request to receive data from the server.
// Return maximum number of bytes to be received by reading from *w5100_data.
#define w5100_receive_request() w5100_data_request(0)

// Commit receiving of <size> bytes from server. <size> may be smaller than
// the return value of w5100_receive_request(). Not commiting at all just
// makes the next request receive the same data again.
#define w5100_receive_commit(size) w5100_data_commit(0, (size))

// Request to send data to the server.
// Return maximum number of bytes to be send by writing to *w5100_data.
#define w5100_send_request() w5100_data_request(1)

// Commit sending of <size> bytes to server. <size> is usually smaller than
// the return value of w5100_send_request(). Not commiting at all just turns
// the w5100_send_request() - and the writes to *w5100_data - into NOPs.
#define w5100_send_commit(size) w5100_data_commit(1, (size))

#endif
