#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

int main() {
  // TODO: Proper error handling for this case
  struct bar { int x; } ?a, b;
  unify(a, b);
}
