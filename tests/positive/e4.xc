#include <unification.xh>
#include <string.xh>
#include <alloca.h>

template<typename a>
struct list {
  a h;
  list<a> ?t;
};

int main() {
  allocate_using stack;
  list<int> l1 = {1, new var<list<int>>()};
  list<int> l2 = {2, new var(l1)};
  list<int> l3 = {3, new var(l2)};
  list<int> l4 = {2, new var<list<int>>()};
  list<int> l5 = {3, new var(l4)};

  printf("%s\n", show(l3).text);
  printf("%s\n", show(l5).text);
  if (!unify(l3, l5)) {
    return 1;
  }
  
  printf("%s\n", show(l3).text);
  printf("%s\n", show(l5).text);
  if (show(l3) != show(l5)) {
    return 2;
  }
}
