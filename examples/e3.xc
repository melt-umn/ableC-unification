#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

typedef datatype Type ?Type;

datatype Type {
  Int();
  List(Type elem);
  Fn(Type param, Type res);
};

var_reference datatype Type with GC_malloc;

string show_type(Type t) {
  match (t) {
    freevar -> {
      char buffer[sizeof(short) * 2 + 2];
      sprintf(buffer, "a%hx", (union {Type t; short n;}){.t = t}.n);
      return str(buffer);
    }
    ?&Int() -> {
      return str("int");
    }
    ?&List(elem) -> {
      return "[" + show_type(elem) + "]";
    }
    ?&Fn(param@?&Fn(_, _), res) -> {
      return "(" + show_type(param) + ") -> " + show_type(res);
    }
    ?&Fn(param, res) -> {
      return show_type(param) + " -> " + show_type(res);
    }
  }
}

int main() {
  // map :: (a -> b) -> [a] -> [b]
  Type a = freevar<datatype Type>(GC_malloc);
  Type b = freevar<datatype Type>(GC_malloc);
  Type map = GC_malloc_Fn(GC_malloc_Fn(a, b), GC_malloc_Fn(GC_malloc_List(a), GC_malloc_List(b)));
  printf("map :: %s\n", show_type(map).text);

  // length :: [c] -> int
  Type c = freevar<datatype Type>(GC_malloc);
  Type length = GC_malloc_Fn(GC_malloc_List(c), GC_malloc_Int());
  printf("length :: %s\n", show_type(length).text);

  // res = map length
  Type res = freevar<datatype Type>(GC_malloc);
  if (unify(map, GC_malloc_Fn(length, res))) {
    printf("map length :: %s\n", show_type(res).text);
  } else {
    printf("type error\n");
    return 1;
  }

  // res :: int -> int
  // Should fail
  if (unify(res, GC_malloc_Fn(GC_malloc_Int(), GC_malloc_Int()))) {
    printf("res :: %s\n", show_type(res).text);
    return 2;
  } else {
    printf("type error\n");
  }
}
