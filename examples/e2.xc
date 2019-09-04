#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

template<typename a>
datatype Tree {
  Node(Tree<a> ?l, Tree<a> ?r);
  Leaf(a val);
};

template var_reference datatype Tree with alloca;

int main() {
  Tree<int> ?a = alloca_Node(alloca_Leaf(42), freevar<Tree<int>>(alloca));
  printf("%s\n", show(a).text);
  Tree<int> ?b = alloca_Node(freevar<Tree<int>>(alloca), alloca_Node(alloca_Leaf(25), freevar<Tree<int>>(alloca)));
  printf("%s\n", show(b).text);

  unification_trail trail = new unification_trail();
  if (unify(a, b, trail)) {
    printf("%s\n", show(trail).text);
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
