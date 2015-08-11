// Both pragmas are obligatory to have cc65 generate code
// suitable to access the W5100 auto-increment registers.
#pragma optimize      (on)
#pragma static-locals (on)

#include <stdio.h>
#include <conio.h>

#include "../supplement/w5100.h"

#define MIN(a,b) (((a)<(b))?(a):(b))

byte ip_addr[4] = {192, 168,   0, 123};
byte submask[4] = {255, 255, 255,   0};
byte gateway[4] = {192, 168,   0,   1};

byte server[4] = {192, 168, 0, 25}; // IP addr of machine running w5100_peer.c

void main(void)
{
  char key;

  videomode(VIDEOMODE_80COL);
  printf("Init\n");
  if (!w5100_init(0xC0B4, ip_addr,
                          submask,
                          gateway))
  {
    printf("No Hardware Found\n");
    return;
  }
  printf("Connect\n");
  if (!w5100_connect(server, 6502))
  {
    printf("Faild To Connect To %d.%d.%d.%d\n", server[0],
                                                server[1],
                                                server[2],
                                                server[3]);
    return;
  }
  printf("Connected To %d.%d.%d.%d\n", server[0],
                                       server[1],
                                       server[2],
                                       server[3]);

  printf("(S)end or e(X)it\n");
  do
  {
    word len, all;

    if (kbhit())
    {
      key = cgetc();
    }
    else
    {
      key = '\0';
    }

    if (key == 's')
    {
      all = 500;
      printf("Send Len %d", all);
      do
      {
        word i;

        while (!(len = w5100_send_request()))
        {
          printf("!");
        }
        len = MIN(all, len);
        for (i = 0; i < len; ++i)
        {
          *w5100_data = 500 - all + i;
        }
        w5100_send_commit(len);
        all -= len;
      }
      while (all);
      printf(".\n");
    }

    len = w5100_receive_request();
    if (len)
    {
      word i;

      printf("Recv Len %d", len);
      for (i = 0; i < len; ++i)
      {
        if ((i % 24) == 0)
        {
          printf("\n$%04X:", i);
        }
        printf(" %02X", *w5100_data);
      }
      w5100_receive_commit(len);
      printf(".\n");
    }

    if (!w5100_connected())
    {
      printf("Disconnect\n");
      return;
    }
  }
  while (key != 'x');

  w5100_disconnect();
  printf("Done\n");
}
