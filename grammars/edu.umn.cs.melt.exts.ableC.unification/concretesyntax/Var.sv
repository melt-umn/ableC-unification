grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax;

marking terminal FreeVar_t 'freevar' lexer classes {Ckeyword};
marking terminal BoundVar_t 'boundvar' lexer classes {Ckeyword};

concrete productions top::PrimaryExpr_c
| FreeVar_t '<' ty::TypeName_c '>' LParen_t allocate::AssignExpr_c ')'
  { top.ast = freeVarExpr(ty.ast, allocate.ast, location=top.location); }
| 'boundvar' LParen_t e::AssignExpr_c ',' allocate::AssignExpr_c ')'
  { top.ast = boundVarExpr(e.ast, allocate.ast, location=top.location); }
