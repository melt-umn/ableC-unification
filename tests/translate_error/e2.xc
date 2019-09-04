#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

// Missing forward declaration of struct bar
// TODO: Raise a proper error message here
struct foo {
  struct bar ?b;
};

struct bar { int x; };

int main() {
  struct bar ?g, h;
  unify(g, h);
}
