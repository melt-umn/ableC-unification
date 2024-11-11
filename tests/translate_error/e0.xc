#include <unification.xh>
#include <string.xh>
#include <stdio.h>
#include <stdlib.h>

datatype Tree {
  Node(datatype Tree ?l, datatype Tree ?r);
  Leaf(int val);
};

int foo(float);

datatype Foo {
  B(datatype Bar ?b);
};

struct bar { int x; };

datatype Bar {
  B1(struct bar ?b);
};

allocate_using heap;

int main() {
  datatype Tree ?a = new var(Node(new var(Leaf(42), new var<datatype Tree>())));
  printf("%s\n", show(a).text);
  datatype Tree ?b = new var(Node(new var<datatype Tree>(), new var(Node(new var(Leaf(25)), new var<datatype Tree>()))));
  printf("%s\n", show(b).text);

  int trail; // Invalid type to unify
  if (unify(a, b, trail)) {
    printf("%s\n", show(trail).text);
    if (trail.size != 2)
      return 2;
    printf("%s\n", show(a).text);
    printf("%s\n", show(b).text);
  } else {
    printf("fail\n");
    return 1;
  }

  undo_trail(trail);
  printf("%s\n", show(a).text);
  printf("%s\n", show(b).text);

  // Invalid types to unify
  int ?c;
  unify(a, c);

  int ???d;
  unify(c, d);

  datatype Foo ?e, ?f;
  unify(e, f);
  unify(e, f); // Same error, repeated

  struct bar ?g, h;
  unify(g, h);
}
