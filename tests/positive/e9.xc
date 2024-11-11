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
  with_arena ar {
    struct foo ?a = new var((struct foo) {
      .bar = new var<struct notDefinedHere*>(),
      .n = new var(5),
    });
    struct foo ?b = new var((struct foo) {
      .bar = new var<struct notDefinedHere*>(),
      .n = new var<int>(),
    });

    unification_trail trail = {};
    assert(unify(a, b, trail));

    assert(value(value(a).n) == 5);
    assert(!is_bound(value(b).n));
  }

  return 0;
}
