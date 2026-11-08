#include <stdio.h>
#include <unistd.h>

/* Harness, not a coreutils program.
   Prints four lines through stdio and waits 100ms between them.
   When stdout is a pipe, glibc fully buffers FILE output unless stdbuf
   (or an explicit flush) changes that. */
int main(void) {
  for (int i = 0; i < 4; i++) {
    printf("line %d\n", i);
    usleep(100000);
  }
  return 0;
}
