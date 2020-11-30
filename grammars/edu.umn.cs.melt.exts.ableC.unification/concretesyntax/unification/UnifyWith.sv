grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax:unification;

import edu:umn:cs:melt:ableC:abstractsyntax:construction;
import edu:umn:cs:melt:exts:ableC:string:concretesyntax; -- 'with', TagKeyword_c
import silver:langutil;

marking terminal Unify_t 'unify' lexer classes {Global, Keyword};

concrete productions top::Declaration_c
| 'unify' '(' ty::TypeName_c ')' 'with' unify::Identifier_t
    { top.ast = unifyWithDecl(ty.ast, fromId(unify)); }
| 'unify' id::TypeName_t 'with' unify::Identifier_t
    { local ty::TypeName = typeName(typedefTypeExpr(nilQualifier(), fromTy(id)), baseTypeExpr());
      top.ast = unifyWithDecl(ty, fromId(unify)); }
| 'unify' kwd::TagKeyword_c id::TypeName_t 'with' unify::Identifier_t
    { local ty::TypeName = typeName(kwd.ast(fromTy(id)), baseTypeExpr());
      top.ast = unifyWithDecl(ty, fromId(unify)); }
