#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

datatype Tree {
  Node(datatype Tree ?l, datatype Tree ?r);
  Leaf(int val);
};


int main() {
  datatype Tree ?a = ?&Node(?&Leaf(42), newvar<datatype Tree>());
  printf("%s\n", show(a).text);
  datatype Tree ?b = ?&Node(newvar<datatype Tree>(), ?&Node(?&Leaf(25), newvar<datatype Tree>()));
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
