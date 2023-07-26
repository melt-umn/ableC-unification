#include <unification.xh>

int foo() {}

int main() {
  int (*?res)() = boundvar(malloc, foo);
}
