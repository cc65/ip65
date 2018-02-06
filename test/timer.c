/* test for timer_seconds function */

#include <stdio.h>
#include <conio.h>

extern void timer_init(void);
extern unsigned int timer_seconds(void);

static int done;

int main(void)
{
  unsigned char sec, sec2, c;
  unsigned int x;

  timer_init();
  printf("Hit <SPACE> to exit...\n");
  sec = timer_seconds();
  printf("%02x\n", sec);
  while (!done) {
    x = timer_seconds();
    sec2 = x & 255;
    if (sec != sec2) {
      sec = sec2;
      printf("%02x\n", sec);
    }
    if (kbhit()) {
      c = cgetc();
      if (c == ' ')
        done = 1;
    }
  }
  return 0;
}
