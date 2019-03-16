#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

int main() {
  int a = 5, ?b = freevar<int>(alloca), ?c = freevar<int>(malloc);
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  if (is_bound(c))
    return 1;
  
  bool res1 = unify(c, b);
  printf("unify 1: %d\n", res1);
  if (!res1)
    return 2;
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  if (is_bound(c))
    return 3;
  
  unification_trail trail = new unification_trail();
  bool res2 = unify(a, b, trail);
  printf("unify 2: %d\n", res2);
  if (!res2)
    return 4;
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  if (!is_bound(c))
    return 5;
  if (value(c) != 5)
    return 6;
  
  bool res3 = unify(b, c);
  printf("unify 3: %d\n", res3);
  if (!res3)
    return 7;
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  if (!is_bound(c))
    return 8;
  if (value(c) != 5)
    return 9;
  
  bool res4 = unify(c, 7);
  printf("unify 4: %d\n", res4);
  if (res4)
    return 10;
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  if (!is_bound(c))
    return 11;
  if (value(c) != 5)
    return 12;
  
  undo_trail(trail, 0);
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  if (is_bound(c))
    return 13;
  
  bool res5 = unify(c, 7);
  printf("unify 5: %d\n", res5);
  if (!res5)
    return 14;
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  if (!is_bound(c))
    return 15;
  if (value(c) != 7)
    return 16;

  int ?e = boundvar(alloca, 42);
  printf("%s %d %d\n", show(e).text, is_bound(e), is_bound(e)? value(e) : -1);
  if (!is_bound(e))
    return 17;
  if (value(e) != 42)
    return 18;

  delete_var(free, c);
}
