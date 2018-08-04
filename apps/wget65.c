#include <cc65.h>
#include <ctype.h>
#include <fcntl.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <dirent.h>
#include <device.h>

#include "../inc/ip65.h"
#include "w5100.h"
#include "linenoise.h"

// Both pragmas are obligatory to have cc65 generate code
// suitable to access the W5100 auto-increment registers.
#pragma optimize      (on)
#pragma static-locals (on)

char buffer[0x1000];

void ip65_error_exit(bool quit)
{
  switch (ip65_error)
  {
  case IP65_ERROR_DEVICE_FAILURE:
    printf("- No Uthernet II found\n");
    break;
  case IP65_ERROR_ABORTED_BY_USER:
    printf("- User abort\n");
    break;
  case IP65_ERROR_TIMEOUT_ON_RECEIVE:
    printf("- Timeout\n");
    break;
  case IP65_ERROR_MALFORMED_URL:
    printf("- Malformed URL\n");
    break;
  case IP65_ERROR_DNS_LOOKUP_FAILED:
    printf("- Lookup failed\n");
    break;
  default:
    printf("- Error $%X\n", ip65_error);
  }
  if (quit)
  {
    exit(EXIT_FAILURE);
  }
}

void file_error_exit(void)
{
  printf("- ");
  perror(NULL);
  exit(EXIT_FAILURE);
}

void confirm_exit(void)
{
  printf("\nPress any key ");
  cgetc();
}

void reset_cwd(void)
{
  chdir("");
}

char *self_path(const char *filename)
{
  extern char **_argv[];

  return strcat(strcpy(buffer, *_argv[0]), filename);
}

bool match(const char *filter, const char *string)
{
  while (*filter)
  {
    if (!*string)
    {
      return false;
    }
    if (toupper(*filter++) != toupper(*string++))
    {
      return false;
    }
  }
  return true;
}

void url_completion(const char *line, linenoiseCompletions *lc)
{
  if (match(line, "http://"))
  {
    linenoiseAddCompletion(lc, "http://");
  }
  if (match(line, "http://www."))
  {
    linenoiseAddCompletion(lc, "http://www.");
  }
}

void file_completion(const char *line, linenoiseCompletions *lc) {
  char *lineptr = strrchr(line, '/');

  // Add device names
  if (lineptr == line)
  {
    unsigned char disk = getfirstdevice();
    while (disk != INVALID_DEVICE)
    {
      if (getdevicedir(disk, buffer, sizeof(buffer)))
      {
        if (match(line, buffer))
        {
          linenoiseAddCompletion(lc, buffer);
        }
      }
      disk = getnextdevice(disk);
    }
  }

  // Add directory entries
  else
  {
    DIR *dir;
    struct dirent *ent;
    char *bufferptr;

    // Absolute or relative path
    if (lineptr)
    {
      *lineptr = '\0';
      dir = opendir(line);
      *lineptr = '/';
      ++lineptr;
    }

    // Current directory
    else
    {
      dir = opendir(".");
      lineptr = (char*)line;
    }

    if (!dir)
    {
      return;
    }

    strcpy(buffer, line);
    bufferptr = buffer + (lineptr - line);

    while (ent = readdir(dir))
    {
      if (match(lineptr, ent->d_name))
      {
        strcpy(bufferptr, ent->d_name);
        linenoiseAddCompletion(lc, buffer);
      }
    }
    closedir(dir);
  }
}

char *get_argument(char arg, const char *name, const char *history,
                   linenoiseCompletionCallback *completion)
{
  extern int _argc;
  extern char **_argv[];
  char *val;

  linenoiseHistoryReset();
  linenoiseHistoryLoad(self_path(history));

  if (_argc > arg)
  {
    val = *_argv[arg];
    printf("%s: %s", name, val);
  }
  else
  {
    char prompt[10];

    linenoiseSetCompletionCallback(completion);

    snprintf(prompt, sizeof(prompt), "%s? ", name);
    val = linenoise(prompt);
    if (!val || !*val)
    {
      putchar('\n');
      exit(EXIT_FAILURE);
    }
  }

  linenoiseHistoryAdd(val);
  linenoiseHistorySave(self_path(history));

  return val;
}

void exit_on_key(void)
{
  if (input_check_for_abort_key())
  {
    w5100_disconnect();
    printf("- User abort\n");
    exit(EXIT_FAILURE);
  }
}

void exit_on_disconnect(void)
{
  if (!w5100_connected())
  {
    printf("- Connection lost\n");
    exit(EXIT_FAILURE);
  }
}

void receive_file(const char *name)
{
  uint16_t i;
  int file;
  uint16_t rcv;
  bool cont = true;
  uint16_t len = 0;
  uint32_t size = 0;

  printf("- Ok\n\nOpening file ");
  file = open(name, O_WRONLY | O_CREAT | O_TRUNC);
  if (file == -1)
  {
    w5100_disconnect();
    file_error_exit();
  }
  printf("- Ok\n\n");

  while (cont)
  {
    exit_on_key();

    rcv = w5100_receive_request();
    if (!rcv)
    {
      cont = w5100_connected();
      if (cont)
      {
        continue;
      }
    }

    if (rcv > sizeof(buffer) - len)
    {
      rcv = sizeof(buffer) - len;
    }

    {
      // One less to allow for faster pre-increment below
      char *dataptr = buffer + len - 1;
      for (i = 0; i < rcv; ++i)
      {
        // The variable is necessary to have cc65 generate code
        // suitable to access the W5100 auto-increment register.
        char data = *w5100_data;
        *++dataptr = data;
      }
    }

    w5100_receive_commit(rcv);
    len += rcv;

    if (cont && len < sizeof(buffer))
    {
      continue;
    }

    cprintf("\rWriting ");
    if (write(file, buffer, len) != len)
    {
      w5100_disconnect();
      file_error_exit();
    }
    size += len;
    cprintf("%lu bytes ", size);

    len = 0;
  }

  printf("- Ok\n\nClosing file ");
  if (close(file))
  {
    w5100_disconnect();
    file_error_exit();
  }
}

int main(int, char *argv[])
{
  uint16_t i;
  char *arg;
  uint8_t drv_init = DRV_INIT_DEFAULT;

  if (doesclrscrafterexit())
  {
    atexit(confirm_exit);
  }

  if (!*getcwd(buffer, sizeof(buffer)))
  {
    // Set a defined working dir before potentially changing devices
    chdir(getdevicedir(getcurrentdevice(), buffer, sizeof(buffer)));
    atexit(reset_cwd);
  }

  // Trim program name from argv[0] to prepare usage in self_path()
  arg = strrchr(argv[0], '/');
  if (arg) {
    *(arg + 1) = '\0';
  }
  else
  {
    *argv[0] = '\0';
  }

  {
    int file;

    printf("\nSetting slot ");
    file = open(self_path("ethernet.slot"), O_RDONLY);
    if (file != -1)
    {
      read(file, &drv_init, 1);
      close(file);
      drv_init &= ~'0';
    }
  }

  printf("- %d\n\nInitializing ", drv_init);
  if (ip65_init(drv_init))
  {
    ip65_error_exit(true);
  }

  // Abort on Ctrl-C to be consistent with Linenoise
  abort_key = 0x83;

  printf("- Ok\n\nObtaining IP address ");
  if (dhcp_init())
  {
    ip65_error_exit(true);
  }
  printf("- Ok\n\n");

  // Copy IP config from IP65 to W5100
  w5100_config();

  while (true)
  {
    arg = get_argument(1, "URL", "wget.urls", url_completion);

    printf("\n\nProcessing URL ");
    if (!url_parse(arg))
    {
      break;
    }

    // Do not actually exit
    ip65_error_exit(false);
    printf("\n");
  }
  printf("- Ok\n\n");

  arg = get_argument(2, "File", "wget.files", file_completion);

  printf("\n\nConnecting to %s:%d ", dotted_quad(url_ip), url_port);

  if (!w5100_connect(url_ip, url_port))
  {
    printf("- Connect failed\n");
    exit(EXIT_FAILURE);
  }

  printf("- Ok\n\nSending request ");
  {
    uint16_t snd;
    uint16_t pos = 0;
    uint16_t len = strlen(url_selector);

    while (len)
    {
      exit_on_key();

      snd = w5100_send_request();
      if (!snd)
      {
        exit_on_disconnect();
        continue;
      }

      if (len < snd)
      {
        snd = len;
      }

      {
        // One less to allow for faster pre-increment below
        char *dataptr = url_selector + pos - 1;
        for (i = 0; i < snd; ++i)
        {
          // The variable is necessary to have cc65 generate code
          // suitable to access the W5100 auto-increment register.
          char data = *++dataptr;
          *w5100_data = data;
        }
      }

      w5100_send_commit(snd);
      len -= snd;
      pos += snd;
    }
  }

  printf("- Ok\n\nReceiving response ");
  {
    uint16_t rcv;
    bool body = false;
    uint16_t len = 0;

    while (!body)
    {
      exit_on_key();

      rcv = w5100_receive_request();
      if (!rcv)
      {
        exit_on_disconnect();
        continue;
      }

      if (rcv > sizeof(buffer) - len)
      {
        rcv = sizeof(buffer) - len;
      }

      {
        // One less to allow for faster pre-increment below
        char *dataptr = buffer + len - 1;
        for (i = 0; i < rcv; ++i)
        {
          // The variable is necessary to have cc65 generate code
          // suitable to access the W5100 auto-increment register.
          char data = *w5100_data;
          *++dataptr = data;

          if (!memcmp(dataptr - 3, "\r\n\r\n", 4))
          {
            rcv = i + 1;
            body = true;
          }
        }
      }

      w5100_receive_commit(rcv);
      len += rcv;

      // No body found in full buffer
      if (len == sizeof(buffer))
      {
        printf("- Invalid response\n");
        w5100_disconnect();
        exit(EXIT_FAILURE);
      }
    }

    // Replace "HTTP/1.1" with "HTTP/1.0"
    buffer[7] = '0';

    if (!match("HTTP/1.0 200", buffer))
    {
      if (match("HTTP/1.0", buffer))
      {
        char *eol = strchr(buffer,'\r');
        *eol = '\0';
        printf("- Status%s\n", buffer + 8);
      }
      else
      {
        printf("- Unknown response\n");
      }
      w5100_disconnect();
      exit(EXIT_FAILURE);
    }
  }

  receive_file(arg);

  printf("- Ok\n\nDisconnecting ");
  w5100_disconnect();

  printf("- Ok\n");
  return EXIT_SUCCESS;
}
