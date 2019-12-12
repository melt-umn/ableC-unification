grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax:unification;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports silver:langutil;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

marking terminal Unify_t 'unify' lexer classes {Keyword, Global};

concrete productions top::PrimaryExpr_c
| 'unify' LParen_t e1::AssignExpr_c ',' e2::AssignExpr_c ')'
  { top.ast = unifyExpr(e1.ast, e2.ast, nothingExpr(), location=top.location); }
| 'unify' LParen_t e1::AssignExpr_c ',' e2::AssignExpr_c ',' trail::AssignExpr_c ')'
  { top.ast = unifyExpr(e1.ast, e2.ast, justExpr(trail.ast), location=top.location); }
