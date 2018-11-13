#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>

template<a>
datatype Tree {
  Node(inst Tree<a> ?l, inst Tree<a> ?r);
  Leaf(a val);
};

int main() {
  inst Tree<int> ?a = ?&inst Node<int>(?&inst Leaf<int>(42), newvar<inst Tree<int>>());
  printf("%s\n", show(a).text);
  inst Tree<int> ?b = ?&inst Node<int>(newvar<inst Tree<int>>(), ?&inst Node<int>(?&inst Leaf<int>(25), newvar<inst Tree<int>>()));
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
