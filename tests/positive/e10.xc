#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

struct foo {
  struct bar ?b;
};

struct bar { int x; };

int main() {
  allocate_using heap;
  struct bar ?g = new var<struct bar>(), h = {42};
  unify(g, h);
}
