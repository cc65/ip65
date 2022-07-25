#include <cc65.h>
#include <fcntl.h>
#include <ctype.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#ifdef __APPLE2__
#include <apple2_filetype.h>
#endif

#include "../inc/ip65.h"
#include "ifttt.h"

char key[80 + 1];
char text[280 + 1];

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

unsigned char cols(void)
{
  unsigned char cols, rows;

  screensize(&cols, &rows);
  return cols;
}

void input(char* str, unsigned int max, const char* tag)
{
  char chr;
  uint8_t row;
  uint16_t len = max / cols() + 1;

  for (row = len; --row; row)
  {
    putchar('\n');
  }
  row = wherey() - len;
  len = 0;

  while (true)
  {
    str[len] = '\0';

    gotoxy(0, row);
    cprintf("%s (%d/%d) \r\n%s", tag, len, max, str);

    cursor(1);
    chr = cgetc();
    cursor(0);

    if (chr == CH_ENTER)
    {
      break;
    }
    if (chr == CH_DEL)
    {
      if (len == 0)
      {
        continue;
      }
      if (wherex() > 0)
      {
        gotox(wherex() - 1);
      }
      else
      {
        gotoxy(cols() - 1, wherey() - 1);
      }
      cputc(' ');
      --len;
      continue;
    }
    if (len == max)
    {
      continue;
    }
    if (isprint(chr))
    {
      str[len++] = chr;
    }
  }
}

int main(void)
{
  int retval;
  uint8_t eth_init = ETH_INIT_DEFAULT;

  if (doesclrscrafterexit())
  {
    atexit(confirm_exit);
  }

  {
    int file;

    printf("\nLoading key ");
    file = open("ifttt.key", O_RDONLY);
    if (file != -1)
    {
      read(file, key, sizeof(key));
      close(file);
      printf("- Ok\n");
    }
    else
    {
      printf("- Failed\n\n\n");
      input(key, sizeof(key) - 1, "IFTTT webhook key");
      if (*key == '\0')
      {
        printf("\n");
        return EXIT_FAILURE;
      }

      printf("\n\nSaving key ");
#ifdef __APPLE2__
      _filetype = PRODOS_T_TXT;
#endif
      file = open("ifttt.key", O_WRONLY | O_CREAT | O_TRUNC);
      if (file != -1)
      {
        write(file, key, sizeof(key));
        close(file);
        printf("- Ok\n");
      }
      else
      {
        printf("- ");
        perror(NULL);
      }
    }
  }

#ifdef __APPLE2__
  {
    int file;

    printf("\nSetting slot ");
    file = open("ethernet.slot", O_RDONLY);
    if (file != -1)
    {
      read(file, &eth_init, 1);
      close(file);
      eth_init &= 0x07;
    }
    printf("- %u\n", eth_init);
  }
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

  printf("- Ok\n\n\n");
  input(text, sizeof(text) - 1, "Text");
  if (*text == '\0')
  {
    printf("\n");
    return EXIT_FAILURE;
  }

  printf("\n\nSending tweet ");
  retval = ifttt_trigger(key, "tweet", text, NULL, NULL);

  if (retval < 0)
  {
    error_exit();
  }
  if (retval != 200)
  {
    printf("- Error (HTTP status %d)\n", retval);
    exit(EXIT_FAILURE);
  }
  printf("- Ok\n");
  return EXIT_SUCCESS;
}
