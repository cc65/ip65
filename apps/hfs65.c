#include <dio.h>
#include <cc65.h>
#include <fcntl.h>
#include <conio.h>
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <device.h>
#include <dirent.h>

#include "../inc/ip65.h"

#ifdef __CBM__
//#define IMAGE ".D64"
#endif
#ifdef __APPLE2__
#define IMAGE ".PO"
#endif
#ifdef __ATARI__
//#define IMAGE ".ATR"
#endif

#define SEND_FIRST 1
#define SEND_LAST  2

unsigned char send_buffer[1024];
unsigned int  send_size;
unsigned char send_type;

void send(unsigned char flags, const char* str, ...)
{
  va_list args;

  if (flags & SEND_FIRST)
  {
    send_size = 0;
    send_type = HTTPD_RESPONSE_200_HTML;
  }

  va_start(args, str);
  send_size += vsnprintf(send_buffer + send_size, sizeof(send_buffer) - send_size, str, args);
  va_end(args);

  if (flags & SEND_LAST || sizeof(send_buffer) - send_size < 1024 / 4)
  {
#ifdef __CBM__
    {
      unsigned char* ptr = send_buffer;
      unsigned char* end = send_buffer + send_size;

      for (; ptr != end; ++ptr)
      {
        *ptr = toascii(*ptr);
      }
    }
#endif

    httpd_send_response(send_type, send_buffer, send_size);
    send_size = 0;
    send_type = HTTPD_RESPONSE_NOHEADER;
  }
}

void error(void)
{
  httpd_send_response(HTTPD_RESPONSE_500, 0, 0);
  printf("500\n");
}

void root(void)
{
  char diskdir[FILENAME_MAX];
  char* rootdir = diskdir;
  unsigned char disk = getfirstdevice();

#ifdef __APPLE2__
  // skip '/'
  ++rootdir;
#endif

  send(SEND_FIRST, "<h2>/</h2><table style='border-spacing: 1em 0em'>");

  while (disk != INVALID_DEVICE)
  {
    if (getdevicedir(disk, diskdir, sizeof(diskdir)))
    {
      send(0, "<tr><td>Disk</td><td><a href='%s'>%s</a></td></tr>",
              rootdir, rootdir);

#ifdef IMAGE
      {
        dhandle_t dio = dio_open(disk);
        if (dio)
        {
          send(0, "<tr><td>Image</td><td><a href='%s"IMAGE"'>%s"IMAGE"</a></td><td align=right>%u</td></tr>",
                  rootdir, rootdir, dio_query_sectcount(dio));
          dio_close(dio);
        }
      }
#endif
    }
    disk = getnextdevice(disk);
  }
  send(SEND_LAST, "</table>");

  printf("200\n");
}

void directory(const char* path)
{
  char* delimiter;
  struct dirent *ent;
  DIR *dir = opendir(".");

  if (!dir)
  {
    error();
    return;
  }

  send(SEND_FIRST, "<h2>%s</h2><table style='border-spacing: 1em 0em'>", path);

  delimiter = strrchr(path, '/');
  if (delimiter && delimiter != path)
  {
    *delimiter = '\0';
    send(0, "<tr><td>Directory</td><td><a href='%s'>..</a></td></tr>", path);
    *delimiter = '/';
  }
  else
  {
    send(0, "<tr><td>Disk</td><td><a href='/'>..</a></td></tr>");
  }

  while (ent = readdir(dir))
  {
    if (_DE_ISREG(ent->d_type))
    {
#ifdef __ATARI__
      send(0, "<tr><td>File</td><td><a href='%s/%s'>%s</a></td></tr>",
              path, ent->d_name, ent->d_name);
#else
      send(0, "<tr><td>File</td><td><a href='%s/%s'>%s</a></td><td align=right>%u</td></tr>",
              path, ent->d_name, ent->d_name, ent->d_blocks);
#endif
      continue;
    }
    if (_DE_ISDIR(ent->d_type))
    {
      send(0, "<tr><td>Directory</td><td><a href='%s/%s'>%s</a></td></tr>",
              path, ent->d_name, ent->d_name);
    }
  }
  send(SEND_LAST, "</table>");

  closedir(dir);
  printf("200\n");
}

unsigned char file(const char* name)
{
  int size;
  int file = open(name, O_RDONLY);

  if (file < 0)
  {
    return 0;
  }

  send_type = HTTPD_RESPONSE_200_DATA;
  while ((size = read(file, send_buffer, sizeof(send_buffer))) > 0)
  {
    httpd_send_response(send_type, send_buffer, size);
    send_type = HTTPD_RESPONSE_NOHEADER;
  }

  close(file);
  printf("200\n");
  return 1;
}

#ifdef IMAGE
void image()
{
  unsigned int sector = 0;
  dhandle_t dio = dio_open(getcurrentdevice());

  if (!dio)
  {
    error();
    return;
  }

  send_size = dio_query_sectsize(dio);
  send_type = HTTPD_RESPONSE_200_DATA;

#ifdef __ATARI__
  #error "TODO: Send ATR header."
  dio_query_sectcount(dio);
#endif

  while (!dio_read(dio, sector++, send_buffer))
  {
    httpd_send_response(send_type, send_buffer, send_size);
    send_type = HTTPD_RESPONSE_NOHEADER;
  }

  dio_close(dio);
  printf("200\n");
}
#endif

void http_server(unsigned long client, const char* method, const char* path)
{
  char* delimiter;

  printf("%s \"%s %s\" ", dotted_quad(client), method, path);

  if (stricmp(method, "get") || path[0] != '/')
  {
    error();
    return;
  }

  if (path[1] == '\0')
  {
    root();
    return;
  }

#ifndef __APPLE2__
  // skip '/'
  ++path;
#endif

  if (!chdir(path))
  {
    directory(path);
    return;
  }

  delimiter = strrchr(path, '/');
  if (delimiter && delimiter != path)
  {
    *delimiter++ = '\0';
    if (!chdir(path) && file(delimiter))
    {
      return;
    }
  }
#ifdef IMAGE
  else
  {
    delimiter = strrchr(path, '.');
    if (delimiter)
    {
      *delimiter = '\0';
      if (!chdir(path))
      {
        image();
        return;
      }
    }
  }
#endif

  httpd_send_response(HTTPD_RESPONSE_404, 0, 0);
  printf("404\n");
}

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
  default:
    printf("- Error $%X\n", ip65_error);
  }

  if (doesclrscrafterexit())
  {
    printf("\nPress any key ");
    cgetc();
  }

  exit(1);
}

void main(void)
{
  char cwd[FILENAME_MAX];

  getcwd(cwd, sizeof(cwd));

#ifdef __APPLE2__
  videomode(VIDEOMODE_80COL);
#endif

  printf("\nHttpFileServer65 v1.0"
         "\n====================="
         "\n\nInitializing ");
  if (ip65_init())
  {
    error_exit();
  }

  printf("- Ok\n\nObtaining IP address ");
  if (dhcp_init())
  {
    error_exit();
  }

  printf("- Ok\n\nStarting server on %s\n\n", dotted_quad(cfg_ip));
  httpd_start(80, http_server);

  chdir(cwd);
}
