#include <cc65.h>
#include <time.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

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
  exit(1);
}

void confirm_exit(void)
{
  printf("\nPress any key ");
  cgetc();
}

void main(void)
{
  unsigned long server, time;

  if (doesclrscrafterexit())
  {
    atexit(confirm_exit);
  }

  printf("\nInitializing ");
  if (ip65_init())
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
  time = sntp_get_time(server);
  if (!time)
  {
    error_exit();
  }

  // Convert time from seconds since 1900 to
  // seconds since 1970 according to RFC 868.
  time -= 2208988800UL;

  printf("- %s", ctime(&time));
}
