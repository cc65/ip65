#include <stdio.h>
#include <conio.h>

#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#pragma comment(lib, "ws2_32.lib")

void main(void)
{
  printf("Init\n");
  WSADATA wsa;
  if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0)
  {
    return;
  }

  SOCKET s = socket(AF_INET, SOCK_DGRAM , IPPROTO_UDP);
  if (s == INVALID_SOCKET)
  {
    return;
  }

  u_long arg = 1;
  if (ioctlsocket(s, FIONBIO, &arg) == SOCKET_ERROR)
  {
    return;
  }

  SOCKADDR_IN local;
  local.sin_family      = AF_INET;
  local.sin_addr.s_addr = INADDR_ANY;
  local.sin_port        = htons(6502);
  if (bind(s, (SOCKADDR *)&local, sizeof(local)) == SOCKET_ERROR)
  {
    return;
  }

  SOCKADDR_IN remote;
  remote.sin_addr.s_addr = INADDR_NONE;

  printf("(S)end or e(X)it\n");
  char key;
  do
  {
    int len;
    unsigned char buf[1500];

    if (kbhit())
    {
      key = getch();
    }
    else
    {
      key = '\0';
    }

    if (key == 's')
    {
      if (remote.sin_addr.s_addr == INADDR_NONE)
      {
        printf("Peer Addr Unknown As Yet\n", len);
      }
      else
      {
        unsigned i;

        len = 512;
        for (i = 0; i < len; ++i)
        {
          buf[i] = i;
        }
        printf("Send Len $%04X To %s", len, inet_ntoa(remote.sin_addr));
        if (sendto(s, buf, len, 0, (SOCKADDR *)&remote, sizeof(remote)) == SOCKET_ERROR)
        {
          return;
        }
        printf(".\n");
      }
    }

    unsigned remote_size = sizeof(remote);
    len = recvfrom(s, buf, sizeof(buf), 0, (SOCKADDR *)&remote, &remote_size);
    if (len == SOCKET_ERROR)
    {
      if (WSAGetLastError() != WSAEWOULDBLOCK)
      {
        return;
      }
      len = 0;
    }
    if (len)
    {
      unsigned i;

      printf("Recv Len $%04X From %s", len, inet_ntoa(remote.sin_addr));
      for (i = 0; i < len; ++i)
      {
        if ((i % 24) == 0)
        {
          printf("\n$%04X:", i);
        }
        printf(" %02X", buf[i]);
      }
      printf(".\n");
    }
  }
  while (key != 'x');

  closesocket(s);
  WSACleanup();
  printf("Done\n");
}
