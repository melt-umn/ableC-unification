#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

allocate_using heap;

int main() {
  int ?a = new var<int>();
  value(a);
}
