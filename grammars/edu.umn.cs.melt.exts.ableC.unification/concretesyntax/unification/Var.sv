grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax:unification;

marking terminal FreeVar_t 'freevar' lexer classes {Keyword, Global};
marking terminal BoundVar_t 'boundvar' lexer classes {Keyword, Global};

concrete productions top::PrimaryExpr_c
| FreeVar_t '<' ty::TypeName_c '>' LParen_t allocate::AssignExpr_c ')'
  { top.ast = freeVarExpr(ty.ast, allocate.ast); }
| 'boundvar' LParen_t allocate::AssignExpr_c ',' e::AssignExpr_c ')'
  { top.ast = boundVarExpr(allocate.ast, e.ast); }
