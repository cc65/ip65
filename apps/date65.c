#include <cc65.h>
#include <time.h>
#include <fcntl.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#ifdef __APPLE2_SYS__
#include <dirent.h>
#include <stdbool.h>
#endif

#include "../inc/ip65.h"

#define NTP_SERVER "pool.ntp.org"

void message_exit(char *msg)
{
  printf("- %s\n", msg);
#ifdef __APPLE2_SYS__
  printf("\nPress any key");
  cgetc();
#endif
  exit(EXIT_FAILURE);
}

void error_exit(void)
{
  message_exit(ip65_strerror(ip65_error));
}

#ifndef __APPLE2__
void confirm_exit(void)
{
  printf("\nPress any key ");
  cgetc();
}
#endif

int main(void)
{
  int tz_hours = 0;
  uint8_t eth_init = ETH_INIT_DEFAULT;
  int file;
  char buf[3];
  uint32_t server;
  struct timespec time;

#ifndef __APPLE2__
  if (doesclrscrafterexit())
  {
    atexit(confirm_exit);
  }
#endif

#ifdef __APPLE2_SYS__
  clrscr();
#endif

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
    eth_init &= 7;
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
    message_exit("Fail");
  }

  printf("- Ok\n");

#ifdef __APPLE2_SYS__
  {
    bool found_myself = false;
    DIR *dir;
    struct dirent *ent;

    printf("\nChaining ");
    dir = opendir(".");
    if (dir)
    {
      while (ent = readdir(dir))
      {
        if (found_myself)
        {
          if (strstr(ent->d_name, ".SYSTEM"))
          {
            printf("- %s ...", ent->d_name);
            exec(ent->d_name, NULL);
          }
        }
        else if (!strcmp(ent->d_name, "DATE65.SYSTEM"))
        {
          found_myself = true;
        }
      }
      closedir(dir);
    }
    message_exit("No .SYSTEM file found");
  }
#endif

  return EXIT_SUCCESS;
}
