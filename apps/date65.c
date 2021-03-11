#include <cc65.h>
#include <time.h>
#include <fcntl.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "../inc/ip65.h"

#define NTP_SERVER "pool.ntp.org"

void error_exit(void)
{
  printf("- %s\n", ip65_strerror(ip65_error));
  exit(EXIT_FAILURE);
}

void confirm_exit(void)
{
  printf("\nPress any key ");
  cgetc();
}

int main(void)
{
  int tz_hours = 0;
  uint8_t eth_init = ETH_INIT_DEFAULT;
  int file;
  char buf[3];
  uint32_t server;
  struct timespec time;

  if (doesclrscrafterexit())
  {
    atexit(confirm_exit);
  }

  printf("\nSetting timezone ");
  file = open("date65.tz", O_RDONLY);
  if (file != -1)
  {
    if (read(file, buf, 3) == 3)
    {
      tz_hours = (buf[2] & ~'0') + 10 * (buf[1] & ~'0');
      if ((buf[0] & ~0x80) == '-')
      {
        tz_hours = -tz_hours;
      }
    }
    close(file);
  }
  if (tz_hours < 0)
  {
    printf("- UTC-%02u\n", -tz_hours);
  }
  else
  {
    printf("- UTC+%02u\n", tz_hours);
  }
  _tz.timezone = tz_hours * 3600L;

#ifdef __APPLE2__
  printf("\nSetting slot ");
  file = open("ethernet.slot", O_RDONLY);
  if (file != -1)
  {
    read(file, &eth_init, 1);
    close(file);
    eth_init &= ~'0';
  }
  printf("- %u\n", eth_init);
#endif

  printf("\nInitializing ");
  if (ip65_init(eth_init))
  {
    error_exit();
  }

  printf("- Ok\n\nObtaining IP address ");
  if (dhcp_init())
  {
    error_exit();
  }

  printf("- Ok\n\nResolving %s ", NTP_SERVER);
  server = dns_resolve(NTP_SERVER);
  if (!server)
  {
    error_exit();
  }

  printf("- Ok\n\nGetting time ");
  time.tv_sec = sntp_get_time(server);
  if (!time.tv_sec)
  {
    error_exit();
  }

  // Convert time from seconds since 1900 to
  // seconds since 1970 according to RFC 868
  time.tv_sec -= 2208988800UL;

  printf("- %s\nSetting time ", ctime(&time.tv_sec));
  time.tv_nsec = 0;
  if (clock_settime(CLOCK_REALTIME, &time))
  {
    printf("- Fail\n");
    exit(EXIT_FAILURE);
  }

  printf("- Ok\n");
  return EXIT_SUCCESS;
}
