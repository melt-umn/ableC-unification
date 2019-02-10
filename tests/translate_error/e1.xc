#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

struct foo;

int main() {
  struct foo ?a, ?b;
  unify(a, b);
  struct bar { int x; } ?c, d;
  unify(c, d);
}
