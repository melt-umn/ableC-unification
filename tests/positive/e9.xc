#include <unification.xh>
#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

struct notDefinedHere;

struct foo {
  struct notDefinedHere*? bar;
  int? n;
};

bool unifyFoo(struct foo l, struct foo r, unification_trail trail) {
  return true;
}

unify struct foo with unifyFoo;

int main() {
  struct foo ?a = boundvar(alloca, (struct foo) {
    .bar = freevar<struct notDefinedHere*>(alloca),
    .n = boundvar(alloca, 5),
  });
  struct foo ?b = boundvar(alloca, (struct foo) {
    .bar = freevar<struct notDefinedHere*>(alloca),
    .n = freevar<int>(alloca),
  });

  unification_trail trail = new unification_trail();
  assert(unify(a, b, trail));

  assert(value(value(a).n) == 5);
  assert(!is_bound(value(b).n));

  return 0;
}
