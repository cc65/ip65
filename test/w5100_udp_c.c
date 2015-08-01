#include <stdio.h>
#include <conio.h>

void __fastcall__ init(void *parms);

unsigned      recv_init(void);
unsigned char recv_byte(void);
void          recv_done(void);

unsigned __fastcall__ send_init(unsigned      len);
void     __fastcall__ send_byte(unsigned char val);
void                  send_done(void);

struct
{
  unsigned char serverip   [4];
  unsigned char cfg_ip     [4];
  unsigned char cfg_netmask[4];
  unsigned char cfg_gateway[4];
}
parms =
{
  {192, 168,   0,   2},
  {192, 168,   0, 123},
  {255, 255, 255,   0},
  {192, 168,   0,   1}
};

void main(void)
{
  char key;

  videomode(VIDEOMODE_80COL);
  printf("Init\n");
  init(&parms);

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

      len = 512;
      printf("Send Len $%04X To %d.%d.%d.%d", len, parms.serverip[0],
                                                   parms.serverip[1],
                                                   parms.serverip[2],
                                                   parms.serverip[3]);
      while (!send_init(len))
      {
        printf("!");
      }
      for (i = 0; i < len; ++i)
      {
        send_byte(i);
      }
      send_done();
      printf(".\n");
    }

    len = recv_init();
    if (len)
    {
      unsigned i;

      printf("Recv Len $%04X From %d.%d.%d.%d", len, parms.serverip[0],
                                                     parms.serverip[1],
                                                     parms.serverip[2],
                                                     parms.serverip[3]);
      for (i = 0; i < len; ++i)
      {
        if ((i % 24) == 0)
        {
          printf("\n$%04X:", i);
        }
        printf(" %02X", recv_byte());
      }
      recv_done();
      printf(".\n");
    }
  }
  while (key != 'x');

  printf("Done\n");
}
