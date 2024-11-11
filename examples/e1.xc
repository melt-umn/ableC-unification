#include <unification.xh>
#include <string.xh>
#include <stdio.h>
#include <stdlib.h>

datatype Tree {
  Node(datatype Tree ?l, datatype Tree ?r);
  Leaf(int val);
};

int main() {
  with_arena ar {
    datatype Tree ?a = new var(Node(new var(Leaf(42)), new var<datatype Tree>()));
    printf("%s\n", show(a).text);
    datatype Tree ?b = new var(Node(new var<datatype Tree>(), new var(Node(new var(Leaf(25)), new var<datatype Tree>()))));
    printf("%s\n", show(b).text);

    unification_trail trail = {};
    push_action(trail, lambda () -> void { printf("First\n"); });
    if (unify(a, b, trail)) {
      printf("%lu\n", trail.size);
      printf("%s\n", show(a).text);
      printf("%s\n", show(b).text);
    } else {
      printf("fail\n");
      return 1;
    }
    push_action(trail, lambda () -> void { printf("Second\n"); });

    undo_trail(trail, 0);
    printf("%s\n", show(a).text);
    printf("%s\n", show(b).text);
  }
}
