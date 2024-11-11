#include <unification.xh>
#include <string.xh>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

allocate_using heap;

int main() {
  int a = 5, ?b = new var<int>(), ?c = new var<int>();
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  
  bool res1 = unify(c, b);
  printf("unify 1: %d\n", res1);
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  
  unification_trail trail = new_trail(arena_create());
  bool res2 = unify(a, b, trail);
  printf("unify 2: %d\n", res2);
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  
  bool res3 = unify(b, c);
  printf("unify 3: %d\n", res3);
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  
  bool res4 = unify(c, 7);
  printf("unify 4: %d\n", res4);
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  
  undo_trail(trail, 0);
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);
  
  bool res5 = unify(c, 7);
  printf("unify 5: %d\n", res5);
  printf("%s %d %d\n", show(c).text, is_bound(c), is_bound(c)? value(c) : -1);

  delete c;

  string ?d = new var<string>();
  bool res6 = unify(d, str("hello"));
  printf("unify 6: %d\n", res6);
  printf("%s %d %s\n", show(d).text, is_bound(d), is_bound(d)? value(d).text : "fail");

  int ?e = new var(42);
  printf("%s %d %d\n", show(e).text, is_bound(e), is_bound(e)? value(e) : -1);
}
