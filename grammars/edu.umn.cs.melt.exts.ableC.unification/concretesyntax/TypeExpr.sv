grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax;

marking terminal Var_t '?';

concrete productions top::Pointer_c
| '?'
    { top.ast = varTypeExpr(nilQualifier(), top.givenType, top.location); }
| '?'  q::TypeQualifierList_c
    { top.ast = varTypeExpr(q.typeQualifiers, top.givenType, top.location); }
| '?'  t::Pointer_c
    { t.givenType = varTypeExpr(nilQualifier(), top.givenType, top.location);
      top.ast = t.ast; }
| '?'  q::TypeQualifierList_c  t::Pointer_c
    { t.givenType = varTypeExpr(q.typeQualifiers, top.givenType, top.location);
      top.ast = t.ast; }
