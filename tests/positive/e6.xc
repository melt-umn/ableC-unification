#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

template<typename a>
datatype Tree {
  Node(Tree<a> ?l, Tree<a> ?r);
  Leaf(a val);
};

template var_reference datatype Tree with alloca prefix a;

int main() {
  Tree<int> ?a = aNode(aLeaf(42), freevar<Tree<int>>(alloca));
  printf("%s\n", show(a).text);
  Tree<int> ?b = aNode(freevar<Tree<int>>(alloca), aNode(aLeaf(25), freevar<Tree<int>>(alloca)));
  printf("%s\n", show(b).text);

  unification_trail trail = new unification_trail();
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
