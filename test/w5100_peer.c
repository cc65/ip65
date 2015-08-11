#include <stdio.h>
#include <conio.h>

#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#pragma comment(lib, "ws2_32.lib")

static void dump(unsigned char *buf, unsigned len)
{
  unsigned i;

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

void main(void)
{
  printf("Init\n");
  WSADATA wsa;
  if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0)
  {
    return;
  }

  SOCKET udp = socket(AF_INET, SOCK_DGRAM , IPPROTO_UDP);
  if (udp == INVALID_SOCKET)
  {
    return;
  }
  SOCKET srv = socket(AF_INET, SOCK_STREAM , IPPROTO_TCP);
  if (srv == INVALID_SOCKET)
  {
    return;
  }

  u_long arg = 1;
  if (ioctlsocket(udp, FIONBIO, &arg) == SOCKET_ERROR)
  {
    return;
  }
  if (ioctlsocket(srv, FIONBIO, &arg) == SOCKET_ERROR)
  {
    return;
  }

  SOCKADDR_IN local;
  local.sin_family      = AF_INET;
  local.sin_addr.s_addr = INADDR_ANY;
  local.sin_port        = htons(6502);
  if (bind(udp, (SOCKADDR *)&local, sizeof(local)) == SOCKET_ERROR)
  {
    return;
  }
  if (bind(srv, (SOCKADDR *)&local, sizeof(local)) == SOCKET_ERROR)
  {
    return;
  }

  if (listen(srv, 1) == SOCKET_ERROR)
  {
    return;
  }

  SOCKADDR_IN remote;
  remote.sin_addr.s_addr = INADDR_NONE;

  SOCKET tcp = INVALID_SOCKET;

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
      if (remote.sin_addr.s_addr == INADDR_NONE && tcp == INVALID_SOCKET)
      {
        printf("Peer Unknown As Yet\n", len);
      }
      else
      {
        unsigned i;

        len = 500;
        for (i = 0; i < len; ++i)
        {
          buf[i] = i;
        }
        if (tcp == INVALID_SOCKET)
        {
          printf("Send Len %d To %s", len, inet_ntoa(remote.sin_addr));
          if (sendto(udp, buf, len, 0, (SOCKADDR *)&remote, sizeof(remote)) == SOCKET_ERROR)
          {
            return;
          }
        }
        else
        {
          printf("Send Len %d", len);
          if (send(tcp, buf, len, 0) == SOCKET_ERROR)
          {
            return;
          }
        }
        printf(".\n");
      }
    }

    unsigned remote_size = sizeof(remote);
    len = recvfrom(udp, buf, sizeof(buf), 0, (SOCKADDR *)&remote, &remote_size);
    if (len == SOCKET_ERROR)
    {
      if (WSAGetLastError() != WSAEWOULDBLOCK)
      {
        return;
      }
    }
    else if (len)
    {
      printf("Recv Len %d From %s", len, inet_ntoa(remote.sin_addr));
      dump(buf, len);
    }

    if (tcp == INVALID_SOCKET)
    {
      SOCKADDR_IN conn;
      unsigned conn_size = sizeof(conn);
      tcp = accept(srv, (SOCKADDR *)&conn, &conn_size);
      if (tcp == INVALID_SOCKET)
      {
        if (WSAGetLastError() != WSAEWOULDBLOCK)
        {
          return;
        }
      }
      else
      {
        printf("Connect From %s\n", inet_ntoa(conn.sin_addr));

        u_long arg = 1;
        if (ioctlsocket(tcp, FIONBIO, &arg) == SOCKET_ERROR)
        {
          return;
        }
      }
    }
    else
    {
      len = recv(tcp, buf, sizeof(buf), 0);
      if (len == SOCKET_ERROR)
      {
        if (WSAGetLastError() != WSAEWOULDBLOCK)
        {
          return;
        }
      }
      else if (len)
      {
        printf("Recv Len %d", len);
        dump(buf, len);
      }
      else
      {
        printf("Disconnect\n");
        closesocket(tcp);
        tcp = INVALID_SOCKET;
      }
    }

    Sleep(10);
  }
  while (key != 'x');

  closesocket(udp);
  closesocket(tcp);
  closesocket(srv);
  WSACleanup();
  printf("Done\n");
}
