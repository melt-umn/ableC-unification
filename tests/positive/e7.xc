#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

typedef struct foo *foo;

string showFoo(foo f) {
  return str("Foo");
}

show foo with showFoo;

int main() {
  printf("%s\n", show(freevar<foo>(alloca)).text);
  printf("%s\n", show(boundvar(alloca, (foo)NULL)).text);
}
