grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax;

marking terminal FreshVar_t 'freshvar' lexer classes {Ckeyword};

concrete productions top::PrimaryExpr_c
| 'freshvar' '<' ty::TypeName_c '>' LParen_t init::AssignExpr_c ')'
  { top.ast = freshVarExpr(ty.ast, init.ast, location=top.location); }
