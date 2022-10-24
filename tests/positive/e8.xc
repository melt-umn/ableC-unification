#include <unification.xh>
#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct rational {
  int? num;
  int? den;
} rational;

int euclid_gcd(int a, int b) {
  assert(a > 0);
  assert(b > 0);
  while(a != b) {
    if(a > b)
      a -= b;
    else
      b -= a;
  }
  return a;
}

bool unifyRational(rational l, rational r, unification_trail trail) {
  size_t trailSizeBefore = trail.size;
  match (l.num, l.den, r.num, r.den) {
    freevar@ln, ?&ld, ?&rn, ?&rd -> {
      int n = ld * rn;
      if(n % rd)
        return false;
      return unify(ln, n / rd, trail);
    }
    ?&ln, freevar@ld, ?&rn, ?&rd -> {
      int n = rd * ln;
      if(n % rn)
        return false;
      return unify(ld, n / rn, trail);
    }
    ?&ln, ?&ld, freevar@rn, ?&rd -> {
      int n = rd * ln;
      if(n % ld)
        return false;
      return unify(rn, n / ld, trail);
    }
    ?&ln, ?&ld, ?&rn, freevar@rd -> {
      int n = ld * rn;
      if(n % ln)
        return false;
      return unify(rd, n / ln, trail);
    }
    ?&ln, freevar@ld, ?&rn, freevar@rd -> {
      int gcd = euclid_gcd(ln, rn);
      return unify(ld, rn / gcd, trail) && unify(rd, ln / gcd, trail);
    }
    ln, ld, rn, rd -> {
      return unify(ln, rn, trail) && unify(ld, rd, trail);
    }
  }
}

unify rational with unifyRational;

int main() {
  rational ?a = boundvar(alloca, (rational) {
    .num = boundvar(alloca, 2),
    .den = boundvar(alloca, 3),
  });
  rational ?b = boundvar(alloca, (rational) {
    .num = boundvar(alloca, 6),
    .den = freevar<int>(alloca),
  });
  rational ?c = boundvar(alloca, (rational) {
    .num = freevar<int>(alloca),
    .den = boundvar(alloca, 6),
  });
  rational ?d = boundvar(alloca, (rational) {
    .num = freevar<int>(alloca),
    .den = freevar<int>(alloca),
  });
  rational ?e = freevar<rational>(alloca);

  unification_trail trail = new unification_trail();
  assert(unify(a, b, trail));
  assert(unify(a, c, trail));
  assert(unify(a, d, trail));
  assert(unify(a, e, trail));

  assert(show(a) == str("{.num = 2, .den = 3}"));
  assert(show(b) == str("{.num = 6, .den = 9}"));
  assert(show(c) == str("{.num = 4, .den = 6}"));
  assert(show(d) == str("{.num = 2, .den = 3}"));
  assert(show(e) == str("{.num = 2, .den = 3}"));

  return 0;
}
