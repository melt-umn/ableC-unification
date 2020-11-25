#include <unification.xh>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

typedef datatype Type ?Type;

datatype Type {
  Fn(Type, Type);
  List(Type);
  Int();
  Bool();
};

var_reference datatype Type with GC_malloc;
show Type with showType;

string showType(Type t) {
  match (t) {
    freevar -> {
      char buffer[sizeof(short) * 2 + 2];
      sprintf(buffer, "a%hx", (union {Type t; short n;}){.t = t}.n);
      return str(buffer);
    }
    ?&Fn(param@?&Fn(_, _), res) -> {
      return "(" + showType(param) + ") -> " + showType(res);
    }
    ?&Fn(param, res) -> {
      return showType(param) + " -> " + showType(res);
    }
    ?&List(elem) -> {
      return "[" + showType(elem) + "]";
    }
    ?&Int() -> {
      return str("int");
    }
    ?&Bool() -> {
      return str("bool");
    }
  }
}

Type freshType() {
  return freevar<datatype Type>(GC_malloc);
}

Type appType(Type f, Type a) {
  Type res = freshType();
  if (!unify(f, Fn(a, res))) {
    printf("Type error applying %s to %s\n", show(f).text, show(a).text);
    exit(1);
  }
  return res;
}

// This example doesn't do freshening - see ableC-rewriting/examples/e3.xc

int main() {
  // map :: (a -> b) -> [a] -> [b]
  Type a = freshType();
  Type b = freshType();
  Type map = GC_malloc_Fn(GC_malloc_Fn(a, b), GC_malloc_Fn(GC_malloc_List(a), GC_malloc_List(b)));
  printf("map :: %s\n", show(map).text);

  // length :: [c] -> int
  Type c = freshType();
  Type length = GC_malloc_Fn(GC_malloc_List(c), GC_malloc_Int());
  printf("length :: %s\n", show(length).text);

  // res = map length
  Type res = appType(map, length);
  printf("map length :: %s\n", show(res).text);

  // res :: int -> int
  // Should fail
  if (unify(res, GC_malloc_Fn(GC_malloc_Int(), GC_malloc_Int()))) {
    printf("res :: %s\n", show(res).text);
    return 2;
  } else {
    printf("type error\n");
  }
}
