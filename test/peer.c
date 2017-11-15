#include <stdio.h>

#ifdef _WIN32
#include <conio.h>
#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#pragma comment(lib, "ws2_32.lib")
#else
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <signal.h>
#include <termios.h>
#define SOCKET int
#define INVALID_SOCKET (-1)
#define SOCKET_ERROR (-1)
#define closesocket close
#define ioctlsocket ioctl
#define SOCKADDR struct sockaddr
#define SOCKADDR_IN struct sockaddr_in
#define getch cgetc

static void Sleep(u_int msec)
{
  struct timespec ts;
  ts.tv_sec = msec / 1000;
  ts.tv_nsec = (long)(msec % 1000) * 1000000;
  nanosleep(&ts, NULL);
}

/* kbhit() and cgetc() for Unix: */

static int __conio_initialized;

static struct termios tty,otty;

static __inline__ void makecooked(void)
{
	tcsetattr(0, TCSANOW, &otty);
}

static void sighand( int num )
{
	signal(SIGINT, SIG_IGN);
	signal(SIGTERM, SIG_IGN);
	signal(SIGHUP, SIG_IGN);
	exit(0);
}

static void exitfn(void)
{
	if (__conio_initialized) makecooked();
	printf("\n");
}

static void makeraw(void)
{
	static int first_call = 1;

	if (first_call) {
		first_call = 0;
		if (tcgetattr(0, &tty)) {  /* input terminal */
			fprintf(stderr, "cannot get terminal attributes: %s\n", strerror(errno));
			exit(1);
		}
		otty=tty;  /* save it */
#ifdef NO_MAKERAW /* makeraw code from NetBSD 1.6.2 (/usr/src/lib/libc/termios/cfmakeraw.c) */
		tty.c_iflag &= ~(IMAXBEL|IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL|IXON);
		tty.c_oflag &= ~OPOST;
		tty.c_lflag &= ~(ECHO|ECHONL|ICANON|ISIG|IEXTEN);
		tty.c_cflag &= ~(CSIZE|PARENB);
		tty.c_cflag |= CS8;
#else
		cfmakeraw(&tty);
#endif
		tty.c_lflag |= ISIG;  /* enable signals from ^C etc. */
		tty.c_oflag |= ONLCR | OPOST; /* translate '\n' to '\r\n' on output */
	}
	tcsetattr(0, TCSANOW, &tty);
}

static void __init_conio(void)
{
	if (! __conio_initialized) {
		signal(SIGINT, sighand);
		signal(SIGTERM, sighand);
		signal(SIGHUP, sighand);
		atexit(exitfn);
		makeraw();
		__conio_initialized = 1;
	}
}

static void __makeraw(void)
{
	if (! __conio_initialized) __init_conio();
	else makeraw();
}

static void __makecooked(void)
{
	if (__conio_initialized) {
		makecooked();
	}
}

static char cgetc (void)
{
	char c;

	__makeraw();
	read(0, &c, 1);
	return c;
}

static unsigned char kbhit (void)
{
	int retval;
	fd_set fds;
	struct timeval tv;

	__makeraw();

 again:
	FD_ZERO(&fds);
	FD_SET(0, &fds);
	tv.tv_sec = tv.tv_usec = 0;
	retval = select(1, &fds, NULL, NULL, &tv);
	if (retval == -1) {
		if (errno == EINTR) goto again;
		__makecooked();
		exit(1);
	}
	if (FD_ISSET(0, &fds)) {
		return 1;
	}
	return 0;
}

#endif

#define LEN 200

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
#ifdef _WIN32
  WSADATA wsa;
  if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0)
  {
    return;
  }
#endif

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

  printf("(U)DP, (T)CP or e(X)it\n");
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

    if (key == 'u' || key == 'U')
    {
      if (remote.sin_addr.s_addr == INADDR_NONE)
      {
        printf("Peer Unknown As Yet\n");
      }
      else
      {
        int i;

        len = LEN;
        for (i = 0; i < len; ++i)
        {
          buf[i] = i;
        }
        printf("Send Len %d To %s", len, inet_ntoa(remote.sin_addr));
        if (sendto(udp, buf, len, 0, (SOCKADDR *)&remote, sizeof(remote)) == SOCKET_ERROR)
        {
          return;
        }
        printf(".\n");
      }
    }

    if (key == 't' || key == 'T')
    {
      if (tcp == INVALID_SOCKET)
      {
        printf("No Connection\n");
      }
      else
      {
        int i;

        len = LEN;
        for (i = 0; i < len; ++i)
        {
          buf[i] = i;
        }
        printf("Send Len %d", len);
        if (send(tcp, buf, len, 0) == SOCKET_ERROR)
        {
          return;
        }
        printf(".\n");
      }
    }

    unsigned remote_size = sizeof(remote);
    len = recvfrom(udp, buf, sizeof(buf), 0, (SOCKADDR *)&remote, &remote_size);
    if (len == SOCKET_ERROR)
    {
#ifdef _WIN32
      if (WSAGetLastError() != WSAEWOULDBLOCK)
      {
        return;
      }
#else
      if (errno != EAGAIN && errno != EWOULDBLOCK)
      {
        return;
      }
#endif
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
#ifdef _WIN32
        if (WSAGetLastError() != WSAEWOULDBLOCK)
        {
          return;
        }
#else
      if (errno != EAGAIN && errno != EWOULDBLOCK)
      {
        return;
      }
#endif
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
#ifdef _WIN32
        if (WSAGetLastError() != WSAEWOULDBLOCK)
        {
          return;
        }
#else
      if (errno != EAGAIN && errno != EWOULDBLOCK)
      {
        return;
      }
#endif
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
  while (key != 'x' && key != 'X');

  closesocket(udp);
  closesocket(tcp);
  closesocket(srv);
#ifdef _WIN32
  WSACleanup();
#endif
  printf("Done\n");
}
