#include <stdio.h>
#include <conio.h>

void __fastcall__ w5100_init(void *parms);

unsigned int  w5100_recv_init(void);
unsigned char w5100_recv_byte(void);
void          w5100_recv_done(void);

unsigned char __fastcall__ w5100_send_init(unsigned int  len);
void          __fastcall__ w5100_send_byte(unsigned char val);
void                       w5100_send_done(void);

struct
{
  unsigned char serverip   [4];
  unsigned char cfg_ip     [4];
  unsigned char cfg_netmask[4];
  unsigned char cfg_gateway[4];
}
parms =
{
  {192, 168,   0,   2}, // IP addr of machine running w5100_peer.c
  {192, 168,   0, 123},
  {255, 255, 255,   0},
  {192, 168,   0,   1}
};

void main(void)
{
  char key;

  videomode(VIDEOMODE_80COL);
  printf("Init\n");
  w5100_init(&parms);

  printf("(S)end or e(X)it\n");
  do
  {
    unsigned len;

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
      unsigned i;

      len = 500;
      printf("Send Len %d To %d.%d.%d.%d", len, parms.serverip[0],
                                                parms.serverip[1],
                                                parms.serverip[2],
                                                parms.serverip[3]);
      while (!w5100_send_init(len))
      {
        printf("!");
      }
      for (i = 0; i < len; ++i)
      {
        w5100_send_byte(i);
      }
      w5100_send_done();
      printf(".\n");
    }

    len = w5100_recv_init();
    if (len)
    {
      unsigned i;

      printf("Recv Len %d From %d.%d.%d.%d", len, parms.serverip[0],
                                                  parms.serverip[1],
                                                  parms.serverip[2],
                                                  parms.serverip[3]);
      for (i = 0; i < len; ++i)
      {
        if ((i % 24) == 0)
        {
          printf("\n$%04X:", i);
        }
        printf(" %02X", w5100_recv_byte());
      }
      w5100_recv_done();
      printf(".\n");
    }
  }
  while (key != 'x');

  printf("Done\n");
}
