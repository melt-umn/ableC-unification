#include <unification.xh>
#include <string.xh>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <alloca.h>

typedef datatype Type ?Type;

datatype Type {
  Fn(Type, Type);
  List(Type);
  Int();
  Bool();
};

size_t showTypeMaxLen(Type t) {
  match (t) {
    ?&Fn(param, res) -> {
      return showMaxLen(param) + showMaxLen(res) + 6;
    }
    ?&List(elem) -> {
      return showMaxLen(elem) + 2;
    }
    _ -> {
      return 5;
    }
  }
}

size_t showType(char *buf, Type t) {
  match (t) {
    freevar -> {
      return sprintf(buf, "a%hx", (union {Type t; short n;}){.t = t}.n);
    }
    ?&Fn(param@?&Fn(_, _), res) -> {
      return buildStr(buf, "(" + show(param) + ") -> " + show(res));
    }
    ?&Fn(param, res) -> {
      return buildStr(buf, show(param) + " -> " + show(res));
    }
    ?&List(elem) -> {
      return buildStr(buf, "[" + show(elem) + "]");
    }
    ?&Int() -> {
      return sprintf(buf, "int");
    }
    ?&Bool() -> {
      return sprintf(buf, "bool");
    }
  }
}

show Type with showTypeMaxLen, showType;

Type freshType(arena_t ar) {
  allocate_using arena ar;
  return new var<datatype Type>();
}

Type appType(Type f, Type a, arena_t ar) {
  allocate_using arena ar;
  Type res = freshType(ar);
  if (!unify(f, Fn(a, res))) {
    allocate_using stack;
    printf("Type error applying %s to %s\n", show(f).text, show(a).text);
    exit(1);
  }
  return res;
}

// This example doesn't do freshening - see ableC-rewriting/examples/e3.xc

int main() {
  with_arena ar {
    // map :: (a -> b) -> [a] -> [b]
    Type a = freshType(ar);
    Type b = freshType(ar);
    Type map = new var(Fn(new var(Fn(a, b)), new var(Fn(new var(List(a)), new var(List(b))))));
    printf("map :: %s\n", show(map).text);

    // length :: [c] -> int
    Type c = freshType(ar);
    Type length = new var(Fn(new var(List(c)), new var(Int())));
    printf("length :: %s\n", show(length).text);

    // res = map length
    Type res = appType(map, length, ar);
    printf("map length :: %s\n", show(res).text);

    // res :: int -> int
    // Should fail
    if (unify(res, new var(Fn(new var(Int()), new var(Int()))))) {
      printf("res :: %s\n", show(res).text);
      return 2;
    } else {
      printf("type error\n");
    }
  }
}
