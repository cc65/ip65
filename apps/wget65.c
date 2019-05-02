#include <dio.h>
#include <cc65.h>
#include <errno.h>
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

// Size needs to be exactly one track of a 16-sector disk
char buffer[0x1000];
char name[16];

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

void dio_error_exit(void)
{
  _seterrno(_osmaperrno(_oserror));
  file_error_exit();
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
  char *lineptr;
  DIR *dir;
  struct dirent *ent;
  char *bufferptr;

  // Add devices
  if (line[0] == '!')
  {
    char device = getfirstdevice();
    while (device != INVALID_DEVICE)
    {
      dhandle_t dio = dio_open(device);
      if (dio)
      {
        // dio_query_sectcount() fails if there's no (formatted) disk
        // in the drive but (in contrast to getdevicedir) it succeeds
        // with a non-ProDOS 16-sector 140k disk which is exactly the
        // check we want here.
        if (dio_query_sectcount(dio))
        {
          sprintf(buffer, "!S%d,D%d", device & 7, (device >> 3) + 1);
          if (match(line, buffer))
          {
            linenoiseAddCompletion(lc, buffer);
          }
        }
        dio_close(dio);
      }
      device = getnextdevice(device);
    }
    return;
  }

  lineptr = strrchr(line, '/');

  // Add device names
  if (lineptr == line)
  {
    char device = getfirstdevice();
    while (device != INVALID_DEVICE)
    {
      if (getdevicedir(device, buffer, sizeof(buffer)))
      {
        if (match(line, buffer))
        {
          linenoiseAddCompletion(lc, buffer);
        }
      }
      device = getnextdevice(device);
    }
    return;
  }

  // Add directory entries
  //
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

  strcpy(buffer, line);
  bufferptr = buffer + (lineptr - line);

  if (name[0] && match(lineptr, name))
  {
    strcpy(bufferptr, name);
    linenoiseAddCompletion(lc, buffer);
  }

  if (!dir)
  {
    return;
  }

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

char *get_argument(char arg, const char *name,
                   linenoiseCompletionCallback *completion)
{
  extern int _argc;
  extern char **_argv[];
  char *val;

  if (_argc > arg)
  {
    val = (*_argv)[arg];
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
  return val;
}

void load_argument(const char *name)
{
  linenoiseHistoryReset();
  linenoiseHistoryLoad(self_path(name));
}

void save_argument(const char *name)
{
  linenoiseHistorySave(self_path(name));
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

void write_file(const char *name)
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

void write_device(char device)
{
  uint16_t i;
  dhandle_t dio;
  uint16_t rcv;
  bool prodos;
  bool cont = true;
  uint16_t len = 0;
  uint16_t num = 0;

  printf("- Ok\n\nOpening drive ");
  dio = dio_open(device);
  if (!dio)
  {
    w5100_disconnect();
    dio_error_exit();
  }

  printf("- Ok\n\nSector order ");

  // The name extension "[P]roDOS sector [O]rder"
  // overrides the default as it's both unambiguous
  // and suitable for any ProDOS drive / disk type.
  if (!strcasecmp(name + strlen(name) - 3, ".PO"))
  {
    prodos = true;
  }

  // Every 140k disk image without .PO extension
  // can be presumed to have DOS 3.3 sector order
  // (usually with extension .DSK or .DO).
  // For all other disk images the DOS 3.3 sector
  // simply just doesn't make any sense.
  else
  {
    prodos = dio_query_sectcount(dio) != 280;
  }
  printf("- %s\n\n", prodos ? "ProDOS" : "DOS 3.3");

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

    {
      // Skewing table containing page offsets to write the successive
      // pages read from the W5100 to - depends on buffer size of 4k !
      static char skew[0x10] = {0x0, 0xE, 0xD, 0xC, 0xB, 0xA, 0x9, 0x8,
                                0x7, 0x6, 0x5, 0x4, 0x3, 0x2, 0x1, 0xF};
      char *dataptr;

      if (prodos)
      {
        if (rcv > sizeof(buffer) - len)
        {
          rcv = sizeof(buffer) - len;
        }

        // One less to allow for faster pre-increment below
        dataptr = buffer + len - 1;
      }
      else
      {
        // Read each page from W5100 individually
        if (rcv > 0x100 - len % 0x100)
        {
          rcv = 0x100 - len % 0x100;
        }

        // One less to allow for faster pre-increment below
        dataptr = buffer + (skew[len / 0x100] << 8 | len % 0x100) - 1;
      }

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
    for (i = 0; i < len; i += 0x200)
    {
      if (dio_write(dio, num++, buffer + i))
      {
        w5100_disconnect();
        dio_error_exit();
      }
    }
    cprintf("%lu bytes ", num * 0x200UL);

    len = 0;
  }

  printf("- Ok\n\nClosing drive ");
  if (dio_close(dio))
  {
    w5100_disconnect();
    dio_error_exit();
  }
}

int main(int, char *argv[])
{
  uint16_t i;
  char *arg;
  char device;
  uint8_t eth_init = ETH_INIT_DEFAULT;

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
      read(file, &eth_init, 1);
      close(file);
      eth_init &= ~'0';
    }
  }

  printf("- %d\n\nInitializing ", eth_init);
  if (ip65_init(eth_init))
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
  w5100_config(eth_init);

  load_argument("wget.urls");
  while (true)
  {
    arg = get_argument(1, "URL", url_completion);

    printf("\n\nProcessing URL ");
    if (!url_parse(arg))
    {
      break;
    }

    // Do not actually exit
    ip65_error_exit(false);
    printf("\n");
  }
  save_argument("wget.urls");
  printf("- Ok\n\n");

  // Try to derive a ProDOS file
  // name (proposal) from the URL
  {
    char *c = strrchr(arg, '/');
    char *dot = NULL;

    i = 0;
    if (c && c[-1] != '/')
    {
      while (*++c)
      {
        // Name must begin with a letter
        if (!i && !isalpha(*c))
        {
          continue;
        }
        // Uppercase looks more familiar
        if (isalnum(*c))
        {
          buffer[i] = toupper(*c);
        }
        // Replace URL encoded char with dot
        else if (*c == '%')
        {
          buffer[i] = '.';
          if (c[1] && c[2])
          {
            c += 2;
          }
        }
        // Memorize begin of name extension
        else if (*c == '.')
        {
          buffer[i] = '.';
          dot = &buffer[i];
        }
        ++i;
      }
    }
    buffer[i] = '\0';

    strncpy(name, buffer, sizeof(name) - 1);

    // Rather cut from base name than from name extension
    if (i > sizeof(name) - 1 && dot)
    {
      uint16_t len = strlen(dot);

      // But keep at least one letter from base name
      if (len > sizeof(name) - 1 - 1)
      {
        len = sizeof(name) - 1 - 1;
      }
      strncpy(name + sizeof(name) - 1 - len, dot, len);
    }
  }

  load_argument("wget.files");
  while (true)
  {
    arg = get_argument(2, "File", file_completion);

    if (arg[0] != '!')
    {
      device = 0;
      break;
    }

    printf("\n\nChecking drive ");

    // !S[1..7],D[1|2]
    if (toupper(arg[1]) == 'S' &&
        arg[2] >= '1' && arg[2] <= '7' &&
        arg[3] == ',' &&
        toupper(arg[4]) == 'D' &&
        arg[5] >= '1' && arg[5] <= '2' &&
        arg[6] == '\0')
    {
      dhandle_t dio;

      device = arg[2] - '0' | arg[5] - '1' << 3;

      // dio_open() succeeeds for every connected drive
      // no matter if it contains any disk at all
      dio = dio_open(device);
      if (dio)
      {
        // dio_query_sectcount() succeeds for every (formatted)
        // 16-sector 140k disk no matter if it is a ProDOS disk
        if (dio_query_sectcount(dio))
        {
          // getdevicedir() succeeds only for ProDOS disks so
          // tell the user the ProDOS volume name of that disk
          // to make sure he doesn't overwrite some important
          // (hard) disk but do not bother him in the (usual?)
          // case of a non-ProDOS 16-sector 140k (game?) disk
          if (getdevicedir(device, buffer, sizeof(buffer)))
          {
            char oldcursor;
            char c;

            printf("- Ok\n\nClobber %s? ", buffer);

            oldcursor = cursor(true);
            c = cgetc();
            cursor(oldcursor);
            if (toupper(c) == 'Y')
            {
              printf("- Yes");
              break;
            }
            printf("- No\n\n");
          }
          else
          {
            printf("- Ok");
            break;
          }
        }
        else
        {
          printf("- Invalid disk\n\n");
        }
        dio_close(dio);
      }
      else
      {
        printf("- Invalid drive\n\n");
      }
    }
    else
    {
      printf("- Malformed drive spec\n\n");
    }
  }
  save_argument("wget.files");

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

  if (device)
  {
    write_device(device);
  }
  else
  {
    write_file(arg);
  }

  printf("- Ok\n\nDisconnecting ");
  w5100_disconnect();

  printf("- Ok\n");
  return EXIT_SUCCESS;
}
