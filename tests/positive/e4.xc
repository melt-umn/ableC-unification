#include <unification.xh>

template<typename a>
struct list {
  a h;
  list<a> ?t;
};

int main() {
  list<int> l1 = {1, freevar<list<int>>(alloca)};
  list<int> l2 = {2, boundvar(alloca, l1)};
  list<int> l3 = {3, boundvar(alloca, l2)};
  list<int> l4 = {2, freevar<list<int>>(alloca)};
  list<int> l5 = {3, boundvar(alloca, l4)};

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
