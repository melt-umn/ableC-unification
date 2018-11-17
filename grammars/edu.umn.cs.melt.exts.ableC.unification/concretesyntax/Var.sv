grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax;

marking terminal FreeVar_t 'freevar' lexer classes {Ckeyword};

concrete productions top::PrimaryExpr_c
| FreeVar_t '<' ty::TypeName_c '>' LParen_t init::AssignExpr_c ')'
  { top.ast = freeVarExpr(ty.ast, init.ast, location=top.location); }
