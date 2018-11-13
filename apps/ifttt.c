#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../inc/ip65.h"
#include "ifttt.h"

static char url[2048];
static char download[2048];

static bool isclean(char c)
{
  switch (c)
  {
    case '*':
    case '-':
    case '.':
    case '_':
      return true;
  }
  return false;
}

static void querystrcat(char* url, const char* val)
{
  if (!val)
  {
    return;
  }

  url += strlen(url);

  while (true)
  {
    if (isalnum(*val) || isclean(*val))
    {
      *url++ = *val++;
      continue;
    }
    if (*val == ' ')
    {
      *url++ = '+';
      ++val;
      continue;
    }
    if (*val == '\0')
    {
      *url = '\0';
      break;
    }
    url += sprintf(url, "%%%02X", toascii(*val++));
  }
}

// Trigger IFTTT maker event via webhook
//
// Inputs: key:   Webhook key to use
//         event: Maker event to trigger
//         val1:  Webhook parameter 'value1'
//         val2:  Webhook parameter 'value2'
//         val3:  Webhook parameter 'value3'
// Output: Webhook HTTP status code, -1 on error
//
int ifttt_trigger(const char* key, const char* event,
                  const char* val1, const char* val2, const char* val3)
{
  char* ptr = url;
  uint16_t len;

  strcpy(url, "http://maker.ifttt.com/trigger/");
  strcat(url, event);
  strcat(url, "/with/key/");
  strcat(url, key);
  strcat(url, "?value1=");
  querystrcat(url, val1);
  strcat(url, "&value2=");
  querystrcat(url, val2);
  strcat(url, "&value3=");
  querystrcat(url, val3);

  while (*ptr)
  {
    *ptr = toascii(*ptr);
    ++ptr;
  }

  if (strlen(url) > 1400)
  {
    ip65_error = IP65_ERROR_MALFORMED_URL;
    return -1;
  }

  len = url_download(url, download, sizeof(download));

  if (len < 12)
  {
    return -1;
  }

  return atoi(download + 9);
}
