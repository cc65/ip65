#include <cc65.h>
#include <time.h>
#include <fcntl.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "../inc/ip65.h"

void error_exit(void)
{
  switch (ip65_error)
  {
  case IP65_ERROR_DEVICE_FAILURE:
    printf("- No device found\n");
    break;
  case IP65_ERROR_ABORTED_BY_USER:
    printf("- User abort\n");
    break;
  case IP65_ERROR_TIMEOUT_ON_RECEIVE:
    printf("- Timeout\n");
    break;
  case IP65_ERROR_DNS_LOOKUP_FAILED:
    printf("- Lookup failed\n");
    break;
  default:
    printf("- Error $%X\n", ip65_error);
  }
  exit(EXIT_FAILURE);
}

void confirm_exit(void)
{
  printf("\nPress any key ");
  cgetc();
}

void main(void)
{
  uint8_t drv_init = DRV_INIT_DEFAULT;
  uint32_t server;
  time_t rawtime;
  struct tm* timeinfo;

  if (doesclrscrafterexit())
  {
    atexit(confirm_exit);
  }

#ifdef __APPLE2__
  {
    int file;

    printf("\nSetting slot ");
    file = open("ethernet.slot", O_RDONLY);
    if (file != -1)
    {
      read(file, &drv_init, 1);
      close(file);
      drv_init &= ~'0';
    }
    printf("- %d\n", drv_init);
  }
#endif

  printf("\nInitializing ");
  if (ip65_init(drv_init))
  {
    error_exit();
  }

  printf("- Ok\n\nObtaining IP address ");
  if (dhcp_init())
  {
    error_exit();
  }

  printf("- Ok\n\nResolving pool.ntp.org ");
  server = dns_resolve("pool.ntp.org");
  if (!server)
  {
    error_exit();
  }

  printf("- Ok\n\nGetting UTC ");
  rawtime = sntp_get_time(server);
  if (!rawtime)
  {
    error_exit();
  }

  // Convert time from seconds since 1900 to
  // seconds since 1970 according to RFC 868
  rawtime -= 2208988800UL;

  timeinfo = localtime(&rawtime);
  printf("- %s", asctime(timeinfo));

#ifdef __APPLE2__
  {
    // See ProDOS 8 Technical Reference Manual
    // Chapter 6.1 - Clock/Calendar Routines
    typedef struct
    {
        unsigned mday :5;
        unsigned mon  :4;
        unsigned year :7;
        uint8_t  min;
        uint8_t  hour;
    }
    dostime_t;
    dostime_t* dostime = (dostime_t*)0xBF90;

    // If DOS time is 0:00 assume no RTC active
    if (!(dostime->hour || dostime->min))
    {
      // Set only DOS date to today
      dostime->year = timeinfo->tm_year % 100;
      dostime->mon  = timeinfo->tm_mon  + 1;
      dostime->mday = timeinfo->tm_mday;
    }
  }
#endif
}
