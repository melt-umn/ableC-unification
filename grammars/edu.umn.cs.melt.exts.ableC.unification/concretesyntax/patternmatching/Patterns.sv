grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax:patternmatching;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports silver:langutil;

imports edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;

marking terminal PatternFreeVar_t 'freevar' lexer classes {Ckeyword};
marking terminal VarRefOp_t '?&' precedence = 1, lexer classes {Csymbol};

concrete productions top::BasicPattern_c
| PatternFreeVar_t
  { top.ast = freeVarPattern(location=top.location); }

concrete productions top::Pattern_c
| VarRefOp_t p1::Pattern_c
  { top.ast = boundVarPattern(p1.ast, location=top.location); }
