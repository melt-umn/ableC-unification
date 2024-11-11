grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax:unification;

import edu:umn:cs:melt:ableC:abstractsyntax:construction;
import silver:langutil;

marking terminal Unify_t 'unify' lexer classes {Global, Keyword};
terminal With_t 'with' lexer classes {Keyword};

concrete productions top::ExternalDeclaration_c
| 'unify' '(' ty::TypeName_c ')' 'with' unify::Identifier_t
    { top.ast = unifyWithDecl(ty.ast, fromId(unify)); }
| 'unify' id::TypeName_t 'with' unify::Identifier_t
    { nondecorated local ty::TypeName =
       typeName(typedefTypeExpr(nilQualifier(), fromTy(id)), baseTypeExpr());
      top.ast = unifyWithDecl(ty, fromId(unify)); }
| 'unify' kwd::TagKeyword_c id::TypeName_t 'with' unify::Identifier_t
    { nondecorated local ty::TypeName = typeName(kwd.ast(fromTy(id)), baseTypeExpr());
      top.ast = unifyWithDecl(ty, fromId(unify)); }

closed tracked nonterminal TagKeyword_c with ast<(BaseTypeExpr ::= Name)>;

concrete productions top::TagKeyword_c
| 'enum'
    { top.ast = tagReferenceTypeExpr(nilQualifier(), enumSEU(), _); }
| 'struct'
    { top.ast = tagReferenceTypeExpr(nilQualifier(), structSEU(), _); }
| 'union'
    { top.ast = tagReferenceTypeExpr(nilQualifier(), unionSEU(), _); }
