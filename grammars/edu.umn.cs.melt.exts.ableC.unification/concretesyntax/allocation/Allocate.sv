grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax:allocation;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:concretesyntax;
imports silver:langutil;

imports edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax hiding Template_t;
imports edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:datatype:concretesyntax hiding Template_t;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;

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
action {
  local constructors::Maybe<[String]> = lookupBy(stringEq, id.lexeme, adtConstructors);
  if (constructors.isJust)
    context =
      addIdentsToScope(
        map(
          \ c::String -> name(alloc.ast.name ++ "_" ++ c, location=id.location),
          constructors.fromJust),
        TemplateIdentifier_t,
        context);
  -- If the datatype hasn't been declared, then do nothing
}
