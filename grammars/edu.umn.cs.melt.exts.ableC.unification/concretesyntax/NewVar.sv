grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax;

marking terminal NewVar_t 'newvar' lexer classes {Ckeyword};

concrete productions top::PrimaryExpr_c
| 'newvar' '<' ty::TypeName_c '>' LParen_t init::AssignExpr_c ')'
  { top.ast = newVarExpr(ty.ast, justExpr(init.ast), location=top.location); }
| 'newvar' '<' ty::TypeName_c '>' LParen_t ')'
  { top.ast = newVarExpr(ty.ast, nothingExpr(), location=top.location); }

marking terminal VarRef_t '?&' lexer classes {Csymbol};

concrete productions top::UnaryOp_c
| '?&'
  { top.ast = varRefExpr(top.expr, location=top.location); }