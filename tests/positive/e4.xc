#include <unification.xh>

template<a>
struct list {
  a h;
  list<a> ?t;
};

int main() {
  list<int> l1 = {1, freevar<list<int>>(alloca)};
  list<int> l2 = {2, boundvar(l1, alloca)};
  list<int> l3 = {3, boundvar(l2, alloca)};
  list<int> l4 = {2, freevar<list<int>>(alloca)};
  list<int> l5 = {3, boundvar(l4, alloca)};

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
