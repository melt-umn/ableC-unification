#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

datatype Tree {
  Node(datatype Tree ?l, datatype Tree ?r);
  Leaf(int val);
};

var_reference datatype Tree with alloca;

int main() {
  datatype Tree ?a = alloca_Node(alloca_Leaf(42), freevar<datatype Tree>(alloca));
  printf("%s\n", show(a).text);
  datatype Tree ?b = alloca_Node(freevar<datatype Tree>(alloca), alloca_Node(alloca_Leaf(25), freevar<datatype Tree>(alloca)));
  printf("%s\n", show(b).text);

  unification_trail trail = new unification_trail();
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

  undo_trail(trail, 0);
  printf("%s\n", show(a).text);
  printf("%s\n", show(b).text);
}
