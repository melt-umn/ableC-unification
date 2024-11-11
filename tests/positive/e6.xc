#include <unification.xh>
#include <string.xh>
#include <stdio.h>
#include <stdlib.h>

template<typename a>
datatype Tree {
  Node(Tree<a> ?l, Tree<a> ?r);
  Leaf(a val);
};

int main() {
  allocate_using heap;
  unification_trail trail = new_trail(arena_create());

  Tree<int> ?a = new var(Node(new var(Leaf(42)), new var<Tree<int>>()));
  printf("%s\n", show(a).text);
  Tree<int> ?b = new var(Node(new var<Tree<int>>(), new var(Node(new var(Leaf(25)), new var<Tree<int>>()))));
  printf("%s\n", show(b).text);

  if (unify(a, b, trail)) {
    printf("%lu\n", trail.size);
    if (trail.size != 2)
      return 2;
    printf("%s\n", show(a).text);
    printf("%s\n", show(b).text);
  } else {
    printf("fail\n");
    return 1;
  }

  undo_trail(trail, 0);
  printf("%s\n", show(a).text);
  printf("%s\n", show(b).text);
}
