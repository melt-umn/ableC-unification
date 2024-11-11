#include <unification.xh>
#include <string.xh>
#include <stdio.h>
#include <stdlib.h>
#include <alloca.h>

typedef struct foo *foo;

size_t showFooMaxLen(foo f) {
  return 3;
}

size_t showFoo(char *buf, foo f) {
  return sprintf(buf, "foo");
}

show foo with showFooMaxLen, showFoo;

int main() {
  allocate_using stack;
  printf("%s\n", show(new var<foo>()).text);
  printf("%s\n", show(new var((foo)NULL)).text);
}
