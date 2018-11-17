grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax;

import edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;

marking terminal VarReference_t 'var_reference' lexer classes {Ckeyword};
terminal NonKeywordVarReference_t 'var_reference';
terminal Datatype_t 'datatype';
terminal With_t 'with';

concrete productions top::Declaration_c
-- id is Identifer_t here to avoid follow spillage
| VarReference_t Datatype_t id::Identifier_t 'with' alloc::Identifier_c ';'
  { top.ast = varReferenceDecl(fromId(id), alloc.ast); }
| 'template' NonKeywordVarReference_t Datatype_t id::Identifier_t 'with' alloc::Identifier_c ';'
  { top.ast = templateVarReferenceDecl(fromId(id), alloc.ast); }
