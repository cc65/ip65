#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "libnet.h"

/*
#define SECONDS_IN_DAY 86400
#define NTP_TO_UNIX = 2208988800 //((70 * 365 + 17) * 86400);
struct tm* __fastcall__ sntp_timestamp_to_tm(unsigned long sntp_timestamp) {
  unsigned long epoch_timestamp=sntp_timestamp-NTP_TO_UNIX;
  return (gmtime(&epoch_timestamp));
}
int main (void)
{
  unsigned long timestamp=0xd2b929e6;
  signed long utc_offset=-10;
  struct tm * _tm;
  timestamp+=(utc_offset*3600);
  _tm=sntp_timestamp_to_tm(timestamp);
  printf ("%02d:%02d:%02d\n",_tm->tm_hour,_tm->tm_min,_tm->tm_sec);
  puts (asctime(_tm));
  return EXIT_SUCCESS;
}

*/

char * addr_to_s(u8* a) {
  static char buffer[16];
  sprintf(buffer,"%u.%u.%u.%u",a[0],a[1],a[2],a[3]);
  return(buffer);
}
void showconfig(void) {
  IP_CONFIG config_p;
  libnet_get_config(&config_p);
  printf ("MAC:      %02x:%02x:%02x:%02x:%02x:%02x\n",libnet_MAC[0],libnet_MAC[1],
                                                      libnet_MAC[2],libnet_MAC[3],
                                                      libnet_MAC[4],libnet_MAC[5],);
  printf ("IP:       %s\n",addr_to_s(config_p.ip_addr));
  printf ("NETMASK:  %s\n",addr_to_s(config_p.netmask));
  printf ("GATEWAY:  %s\n",addr_to_s(config_p.gateway_addr));
  printf ("DNS:      %s\n",addr_to_s(config_p.dns_server_addr));
}
int main (void)
{
  IP_CONFIG _default_config ={
    {1,2,3,4},        //IP address
    {255,255,255,0},  // netmask
    {192,168,1,1},    //default gateway
    {192,168,2,1},    // dns server
  };

  libnet_err_t ln_err;
  
//  ln_err=libnet_init(&_default_config);
  ln_err=libnet_init(LIBNET_USE_DHCP);  

  printf("result: %02x\n",ln_err);
  showconfig();
  return EXIT_SUCCESS;
} 
