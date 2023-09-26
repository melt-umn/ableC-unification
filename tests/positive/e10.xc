#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

struct foo {
  struct bar ?b;
};

struct bar { int x; };

int main() {
  struct bar ?g = freevar<struct bar>(alloca), h = {42};
  unify(g, h);
}
