#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

template<a>
datatype Tree {
  Node(inst Tree<a> ?l, inst Tree<a> ?r);
  Leaf(a val);
};

template var_reference datatype Tree with alloca;

int main() {
  inst Tree<int> ?a = inst alloca_Node<int>(inst alloca_Leaf<int>(42), freevar<inst Tree<int>>(alloca));
  printf("%s\n", show(a).text);
  inst Tree<int> ?b = inst alloca_Node<int>(freevar<inst Tree<int>>(alloca), inst alloca_Node<int>(inst alloca_Leaf<int>(25), freevar<inst Tree<int>>(alloca)));
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

  undo_trail(trail);
  printf("%s\n", show(a).text);
  printf("%s\n", show(b).text);
}
