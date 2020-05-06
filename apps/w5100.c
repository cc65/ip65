/******************************************************************************

Copyright (c) 2015, Oliver Schmidt
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

// The W5100 has the undocumented feature to wrap around the Address Register
// on an Auto-Increment at the end of physical address space to its beginning.
//
// However, the only way to make use of that feature is to have only a single
// socket that uses all of the W5100 physical address space. But having only
// a single socket by defining SINGLE_SOCKET comes with downsides too:
//
// One mustn't call into IP65 network functions anymore after w5100_config().
// Additionally the program doesn't support 'W5100 Shared Access' anymore
// (https://github.com/a2retrosystems/uthernet2/wiki/W5100-Shared-Access).

#ifdef SINGLE_SOCKET
#define SOCK_REG(offset) (0x0400 | (offset))
#else // SINGLE_SOCKET
#define SOCK_REG(offset) (0x0500 | (offset))
#endif // SINGLE_SOCKET

// Both pragmas are obligatory to have cc65 generate code
// suitable to access the W5100 auto-increment registers.
#pragma optimize      (on)
#pragma static-locals (on)

#include "../inc/ip65.h"
#include "w5100.h"

#define MIN(a,b) (((a)<(b))?(a):(b))

static volatile uint8_t* w5100_mode;
static volatile uint8_t* w5100_addr_hi;
static volatile uint8_t* w5100_addr_lo;
       volatile uint8_t* w5100_data;

static uint16_t addr_basis[2];
static uint16_t addr_limit[2];
static uint16_t addr_mask [2];

static void set_addr(uint16_t addr)
{
  // The variables are necessary to have cc65 generate code
  // suitable to access the W5100 auto-increment registers.
  uint8_t addr_hi = addr >> 8;
  uint8_t addr_lo = addr;
  *w5100_addr_hi = addr_hi;
  *w5100_addr_lo = addr_lo;
}

static uint8_t get_byte(uint16_t addr)
{
  set_addr(addr);

  return *w5100_data;
}

static void set_byte(uint16_t addr, uint8_t data)
{
  set_addr(addr);

  *w5100_data = data;
}

static uint16_t get_word(uint16_t addr)
{
  set_addr(addr);

  {
    // The variables are necessary to have cc65 generate code
    // suitable to access the W5100 auto-increment registers.
    uint8_t data_hi = *w5100_data;
    uint8_t data_lo = *w5100_data;
    return data_hi << 8 | data_lo;
  }
}

static void set_word(uint16_t addr, uint16_t data)
{
  set_addr(addr);

  {
    // The variables are necessary to have cc65 generate code
    // suitable to access the W5100 auto-increment registers.
    uint8_t data_hi = data >> 8;
    uint8_t data_lo = data;
    *w5100_data = data_hi;
    *w5100_data = data_lo;
  }
}

static void set_quad(uint16_t addr, uint32_t data)
{
  set_addr(addr);

  {
    // The variables are necessary to have cc65 generate code
    // suitable to access the W5100 auto-increment registers.
    uint8_t data_1 = data;
    uint8_t data_2 = data >> 8;
    uint8_t data_3 = data >> 16;
    uint8_t data_4 = data >> 24;
    *w5100_data = data_1;
    *w5100_data = data_2;
    *w5100_data = data_3;
    *w5100_data = data_4;
  }
}

void w5100_config(uint8_t eth_init)
{
  w5100_mode    = (uint8_t*)(eth_init << 4 | 0xC084);
  w5100_addr_hi = w5100_mode + 1;
  w5100_addr_lo = w5100_mode + 2;
  w5100_data    = w5100_mode + 3;

#ifdef SINGLE_SOCKET

  // IP65 is inhibited so disable the W5100 Ping Block Mode.
  *w5100_mode &= ~0x10;

#endif // SINGLE_SOCKET

  // Source IP Address Register
  set_quad(0x000F, cfg_ip);

  // Subnet Mask Register
  set_quad(0x0005, cfg_netmask);

  // Gateway IP Address Register
  set_quad(0x0001, cfg_gateway);

  {
    bool do_send;
    for (do_send = false; do_send <= true; ++do_send)
    {
      static uint16_t reg[2] = {0x001A,  // RX Memory Size Register
                                0x001B}; // TX Memory Size Register

      static uint16_t addr[2] = {0x6000,  // RX Memory
                                 0x4000}; // TX Memory

      static uint16_t size[4] = {0x0400,  // 1KB Memory
                                 0x0800,  // 2KB Memory
                                 0x1000,  // 4KB Memory
                                 0x2000}; // 8KB Memory

#ifdef SINGLE_SOCKET

      set_byte(reg[do_send], 0x03);

      // Set Socket 0 Memory Size to 8KB
      addr_basis[do_send] = addr      [do_send];
      addr_limit[do_send] = addr_basis[do_send] + size[0x03];
      addr_mask [do_send] =                       size[0x03] - 1;

#else // SINGLE_SOCKET

      uint8_t sizes = get_byte(reg[do_send]);

      // Get Socket 1 Memory Size
      addr_basis[do_send] = addr      [do_send] + size[sizes      & 0x03];
      addr_limit[do_send] = addr_basis[do_send] + size[sizes >> 2 & 0x03];
      addr_mask [do_send] =                       size[sizes >> 2 & 0x03] - 1;

#endif // SINGLE_SOCKET
    }
  }
}

bool w5100_connect(uint32_t addr, uint16_t port)
{
  // Socket x Mode Register: TCP
  set_byte(SOCK_REG(0x00), 0x01);

  // Socket x Source Port Register
  set_word(SOCK_REG(0x04), ip65_random_word());

  // Socket x Command Register: OPEN
  set_byte(SOCK_REG(0x01), 0x01);

  // Socket x Status Register: SOCK_INIT ?
  while (get_byte(SOCK_REG(0x03)) != 0x13)
  {
    if (input_check_for_abort_key())
    {
      return false;
    }
  }

  // Socket x Destination IP Address Register
  set_quad(SOCK_REG(0x0C), addr);

  // Socket x Destination Port Register
  set_word(SOCK_REG(0x10), port);

  // Socket x Command Register: CONNECT
  set_byte(SOCK_REG(0x01), 0x04);

  while (true)
  {
    // Socket x Status Register
    switch (get_byte(SOCK_REG(0x03)))
    {
      case 0x00: return false; // Socket Status: SOCK_CLOSED
      case 0x17: return true;  // Socket Status: SOCK_ESTABLISHED
    }

    if (input_check_for_abort_key())
    {
      return false;
    }
  }
}

bool w5100_connected(void)
{
  // Socket x Status Register: SOCK_ESTABLISHED ?
  return get_byte(SOCK_REG(0x03)) == 0x17;
}

void w5100_disconnect(void)
{
  // Socket x Command Register: Command Pending ?
  while (get_byte(SOCK_REG(0x01)))
  {
    if (input_check_for_abort_key())
    {
      return;
    }
  }

  // Socket x Command Register: DISCON
  set_byte(SOCK_REG(0x01), 0x08);
}

uint16_t w5100_data_request(bool do_send)
{
  // Socket x Command Register: Command Pending ?
  if (get_byte(SOCK_REG(0x01)))
  {
    return 0;
  }

  {
    uint16_t size = 0;
    uint16_t prev_size;

    // Reread of nonzero RX Received Size Register / TX Free Size Register
    // until its value settles ...
    // - is present in the WIZnet driver - getSn_RX_RSR() / getSn_TX_FSR()
    // - was additionally tested on 6502 machines to be actually necessary
    do
    {
      prev_size = size;
      {
        static uint16_t reg[2] = {SOCK_REG(0x26),  // Socket x RX Received Size Register
                                  SOCK_REG(0x20)}; // Socket x TX Free     Size Register
        size = get_word(reg[do_send]);
      }
    }
    while (size != prev_size);

    if (!size)
    {
      return 0;
    }

    {
      static uint16_t reg[2] = {SOCK_REG(0x28),  // Socket x RX Read  Pointer Register
                                SOCK_REG(0x24)}; // Socket x TX Write Pointer Register

      // Calculate and set physical address
      uint16_t addr = get_word(reg[do_send]) & addr_mask [do_send]
                                             | addr_basis[do_send];
      set_addr(addr);

#ifdef SINGLE_SOCKET

      // The W5100 has the undocumented feature to wrap around the Address Register
      // on an Auto-Increment at the end of physical address space to its beginning.
      return size;

#else // SINGLE_SOCKET

      // Access to *w5100_data is limited both by ...
      // - size of received / free space
      // - end of physical address space
      return MIN(size, addr_limit[do_send] - addr);

#endif // SINGLE_SOCKET
    }
  }
}

void w5100_data_commit(bool do_send, uint16_t size)
{
  {
    static uint16_t reg[2] = {SOCK_REG(0x28),  // Socket x RX Read  Pointer Register
                              SOCK_REG(0x24)}; // Socket x TX Write Pointer Register
    set_word(reg[do_send], get_word(reg[do_send]) + size);
  }

  {
    static uint8_t cmd[2] = {0x40,  // Socket Command: RECV
                             0x20}; // Socket Command: SEND
    // Socket x Command Register
    set_byte(SOCK_REG(0x01), cmd[do_send]);
  }

  // Do NOT wait for command completion here, rather
  // let W5100 operation overlap with 6502 operation
}
