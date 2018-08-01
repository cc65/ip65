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

void w5100_config(void)
{
  w5100_mode    = eth_driver_io_base;
  w5100_addr_hi = eth_driver_io_base + 1;
  w5100_addr_lo = eth_driver_io_base + 2;
  w5100_data    = eth_driver_io_base + 3;

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
      uint8_t sizes = get_byte(reg[do_send]);

      static uint16_t addr[2] = {0x6000,  // RX Memory
                                 0x4000}; // TX Memory

      static uint16_t size[4] = {0x0400,  // 1KB Memory
                                 0x0800,  // 2KB Memory
                                 0x1000,  // 4KB Memory
                                 0x2000}; // 8KB Memory

      addr_basis[do_send] = addr      [do_send] + size[sizes      & 3];
      addr_limit[do_send] = addr_basis[do_send] + size[sizes >> 2 & 3];
    }
  }
}

bool w5100_connect(uint32_t addr, uint16_t port)
{
  // Socket 1 Mode Register: TCP
  set_byte(0x0500, 0x01);

  // Socket 1 Source Port Register
  set_word(0x0504, ip65_random_word());

  // Socket 1 Command Register: OPEN
  set_byte(0x0501, 0x01);

  // Socket 1 Status Register: SOCK_INIT ?
  while (get_byte(0x0503) != 0x13)
  {
    if (input_check_for_abort_key())
    {
      return false;
    }
  }

  // Socket 1 Destination IP Address Register
  set_quad(0x050C, addr);

  // Socket 1 Destination Port Register
  set_word(0x0510, port);

  // Socket 1 Command Register: CONNECT
  set_byte(0x0501, 0x04);

  while (true)
  {
    // Socket 1 Status Register
    switch (get_byte(0x0503))
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
  // Socket 1 Status Register: SOCK_ESTABLISHED ?
  return get_byte(0x0503) == 0x17;
}

void w5100_disconnect(void)
{
  // Socket 1 Command Register: Command Pending ?
  while (get_byte(0x0501))
  {
    if (input_check_for_abort_key())
    {
      return;
    }
  }

  // Socket 1 Command Register: DISCON
  set_byte(0x0501, 0x08);
}

uint16_t w5100_data_request(bool do_send)
{
  // Socket 1 Command Register: Command Pending ?
  if (get_byte(0x0501))
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
        static uint16_t reg[2] = {0x0526,  // Socket 1 RX Received Size Register
                                  0x0520}; // Socket 1 TX Free     Size Register
        size = get_word(reg[do_send]);
      }
    }
    while (size != prev_size);

    if (!size)
    {
      return 0;
    }

    {
      static uint16_t reg[2] = {0x0528,  // Socket 1 RX Read  Pointer Register
                                0x0524}; // Socket 1 TX Write Pointer Register

      // Calculate and set physical address
      uint16_t addr = get_word(reg[do_send]) & 0x0FFF | addr_basis[do_send];
      set_addr(addr);

      // Access to *w5100_data is limited both by ...
      // - size of received / free space
      // - end of physical address space
      return MIN(size, addr_limit[do_send] - addr);
    }
  }
}

void w5100_data_commit(bool do_send, uint16_t size)
{
  {
    static uint16_t reg[2] = {0x0528,  // Socket 1 RX Read  Pointer Register
                              0x0524}; // Socket 1 TX Write Pointer Register
    set_word(reg[do_send], get_word(reg[do_send]) + size);
  }

  {
    static uint8_t cmd[2] = {0x40,  // Socket Command: RECV
                             0x20}; // Socket Command: SEND
    // Socket 1 Command Register
    set_byte(0x0501, cmd[do_send]);
  }

  // Do NOT wait for command completion here, rather
  // let W5100 operation overlap with 6502 operation
}
