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

#ifndef _W5100_H_
#define _W5100_H_

#ifndef __APPLE2ENH__
#error W5100 auto-increment register access requires 65C02.
#endif

#include <stdint.h>
#include <stdbool.h>

uint16_t w5100_data_request(bool do_send);
void w5100_data_commit(bool do_send, uint16_t size);

// After w5100_receive_request() every read operation returns the next byte
// from the server.
// After w5100_send_request() every write operation prepares the next byte
// to be sent to the server.
extern volatile uint8_t* w5100_data;

// Configure W5100 Ethernet controller with additional information from IP65
// after the IP65 TCP/IP stack has been configured.
void w5100_config(uint8_t eth_init);

// Connect to server with IP address <server_addr> on TCP port <server_port>.
// Return true if the connection is established, return false otherwise.
bool w5100_connect(uint32_t addr, uint16_t port);

// Check if still connected to server.
// Return true if the connection is established, return false otherwise.
bool w5100_connected(void);

// Disconnect from server.
void w5100_disconnect(void);

// Request to receive data from the server.
// Return maximum number of bytes to be received by reading from *w5100_data.
#define w5100_receive_request() w5100_data_request(false)

// Commit receiving of <size> bytes from server. <size> may be smaller than
// the return value of w5100_receive_request(). Not commiting at all just
// makes the next request receive the same data again.
#define w5100_receive_commit(size) w5100_data_commit(false, (size))

// Request to send data to the server.
// Return maximum number of bytes to be send by writing to *w5100_data.
#define w5100_send_request() w5100_data_request(true)

// Commit sending of <size> bytes to server. <size> is usually smaller than
// the return value of w5100_send_request(). Not commiting at all just turns
// the w5100_send_request() - and the writes to *w5100_data - into NOPs.
#define w5100_send_commit(size) w5100_data_commit(true, (size))

#endif
