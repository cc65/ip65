#include <cc65.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

#include "../inc/ip65.h"

#define LEN 500
#define SRV "192.168.0.10"

char buf[LEN];

void error_exit(void)
{
  printf("Error $%X\n", ip65_error);
  if (doesclrscrafterexit())
  {
    printf("Press any key\n");
    cgetc();
  }
  exit(1);
}

void udp_recv(void)
{
  unsigned len = udp_recv_len();
  unsigned i;

  printf("Recv Len %u From %s", len, dotted_quad(udp_recv_src()));
  for (i = 0; i < len; ++i)
  {
    if ((i % 11) == 0)
    {
      printf("\n$%04X:", i);
    }
    printf(" %02X", udp_recv_buf[i]);
  }
  printf(".\n");
}

void main(void)
{
  unsigned i;
  unsigned long srv;
  char key;

  for (i = 0; i < LEN; ++i)
    buf[i] = i;

  if(!(srv = parse_dotted_quad(SRV)))
  {
    error_exit();
  }

  printf("Init\n");
  if (ip65_init())
  {
    error_exit();
  }

  printf("DHCP\n");
  if (dhcp_init())
  {
    error_exit();
  }

  printf("IP Addr: %s\n", dotted_quad(cfg_ip));
  printf("Netmask: %s\n", dotted_quad(cfg_netmask));
  printf("Gateway: %s\n", dotted_quad(cfg_gateway));
  printf("DNS Srv: %s\n", dotted_quad(cfg_dns));

  printf("Listen\n");
  if (udp_add_listener(6502, udp_recv))
  {
    error_exit();
  }

  printf("(U)DP or e(X)it\n");
  do
  {
    ip65_process();

    if (kbhit())
    {
      key = cgetc();
    }
    else
    {
      key = '\0';
    }

    if (key == 'u')
    {
      printf("Send Len %d To %s", LEN, SRV);
      if (udp_send(buf, LEN, srv, 6502, 6502))
      {
        printf("!\n");
      }
      else
      {
        printf(".\n");
      }
    }
  }
  while (key != 'x');

  printf("Unlisten\n");
  if (udp_remove_listener(6502))
  {
    error_exit();
  }

  printf("Done\n");
}
