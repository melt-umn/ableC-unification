#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

int main() {
  int ?a = freevar<int>(alloca);
  inst value<int>(a);
}
