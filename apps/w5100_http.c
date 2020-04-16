/******************************************************************************

Copyright (c) 2020, Oliver Schmidt
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

#include <stdio.h>
#include <string.h>

#include "../inc/ip65.h"
#include "w5100.h"
#include "w5100_http.h"

// Both pragmas are obligatory to have cc65 generate code
// suitable to access the W5100 auto-increment registers.
#pragma optimize      (on)
#pragma static-locals (on)

bool w5100_http_open(uint32_t addr, uint16_t port, const char* selector,
                     char* buffer, size_t length)
{
  printf("Connecting to %s:%d ", dotted_quad(addr), port);

  if (!w5100_connect(addr, port))
  {
    printf("- Connect failed\n");
    return false;
  }

  printf("- Ok\n\nSending request ");
  {
    uint16_t snd;
    uint16_t pos = 0;
    uint16_t len = strlen(selector);

    while (len)
    {
      if (input_check_for_abort_key())
      {
        printf("- User abort\n");
        w5100_disconnect();
        return false;
      }

      snd = w5100_send_request();
      if (!snd)
      {
        if (!w5100_connected())
        {
          printf("- Connection lost\n");
          return false;
        }
        continue;
      }

      if (len < snd)
      {
        snd = len;
      }

      {
        // One less to allow for faster pre-increment below
        const char *dataptr = selector + pos - 1;
        uint16_t i;
        for (i = 0; i < snd; ++i)
        {
          // The variable is necessary to have cc65 generate code
          // suitable to access the W5100 auto-increment register.
          char data = *++dataptr;
          *w5100_data = data;
        }
      }

      w5100_send_commit(snd);
      len -= snd;
      pos += snd;
    }
  }

  printf("- Ok\n\nReceiving response ");
  {
    uint16_t rcv;
    bool body = false;
    uint16_t len = 0;

    while (!body)
    {
      if (input_check_for_abort_key())
      {
        printf("- User abort\n");
        w5100_disconnect();
        return false;
      }

      rcv = w5100_receive_request();
      if (!rcv)
      {
        if (!w5100_connected())
        {
          printf("- Connection lost\n");
          return false;
        }
        continue;
      }

      if (rcv > length - len)
      {
        rcv = length - len;
      }

      {
        // One less to allow for faster pre-increment below
        char *dataptr = buffer + len - 1;
        uint16_t i;
        for (i = 0; i < rcv; ++i)
        {
          // The variable is necessary to have cc65 generate code
          // suitable to access the W5100 auto-increment register.
          char data = *w5100_data;
          *++dataptr = data;

          if (!memcmp(dataptr - 3, "\r\n\r\n", 4))
          {
            rcv = i + 1;
            body = true;
          }
        }
      }

      w5100_receive_commit(rcv);
      len += rcv;

      // No body found in full buffer
      if (len == sizeof(buffer))
      {
        printf("- Invalid response\n");
        w5100_disconnect();
        return false;
      }
    }

    // Replace "HTTP/1.1" with "HTTP/1.0"
    buffer[7] = '0';

    if (memcmp(buffer, "HTTP/1.0 200", 12))
    {
      if (!memcmp(buffer, "HTTP/1.0", 8))
      {
        char *eol = strchr(buffer,'\r');
        *eol = '\0';
        printf("- Status%s\n", buffer + 8);
      }
      else
      {
        printf("- Unknown response\n");
      }
      w5100_disconnect();
      return false;
    }
  }
  return true;
}
