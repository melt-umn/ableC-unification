grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax:allocation;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:concretesyntax;
imports silver:langutil;

imports edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax hiding Template_t;
imports edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:datatype:concretesyntax hiding Template_t;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;

marking terminal VarReference_t 'var_reference' lexer classes {Keyword, Global};
terminal NonMarkingVarReference_t 'var_reference' lexer classes {Keyword};
terminal Datatype_t 'datatype' lexer classes {Keyword};
terminal With_t 'with' lexer classes {Keyword};
terminal Prefix_t 'prefix' lexer classes {Keyword};

concrete productions top::Declaration_c
-- id is Identifer_t here to avoid follow spillage
| VarReference_t Datatype_t id::Identifier_t 'with' alloc::Identifier_c ';'
  { top.ast = varReferenceDecl(fromId(id), alloc.ast, nothing()); }
action {
  local constructors::Maybe<[String]> = lookup(id.lexeme, adtConstructors);
  if (constructors.isJust)
    context =
      addIdentsToScope(
        map(
          \ c::String -> name(alloc.ast.name ++ "_" ++ c),
          constructors.fromJust),
        Identifier_t,
        context);
  -- If the datatype hasn't been declared, then do nothing
}
| VarReference_t Datatype_t id::Identifier_t 'with' alloc::Identifier_t 'prefix' pfx::Identifier_c ';'
  { top.ast = varReferenceDecl(fromId(id), fromId(alloc), just(pfx.ast)); }
action {
  local constructors::Maybe<[String]> = lookup(id.lexeme, adtConstructors);
  if (constructors.isJust)
    context =
      addIdentsToScope(
        map(
          \ c::String -> name(pfx.ast.name ++ c),
          constructors.fromJust),
        Identifier_t,
        context);
  -- If the datatype hasn't been declared, then do nothing
}
| 'template' NonMarkingVarReference_t Datatype_t id::Identifier_t 'with' alloc::Identifier_c ';'
  { top.ast = templateVarReferenceDecl(fromId(id), alloc.ast, nothing()); }
action {
  local constructors::Maybe<[String]> = lookup(id.lexeme, adtConstructors);
  if (constructors.isJust)
    context =
      addIdentsToScope(
        map(
          \ c::String -> name(alloc.ast.name ++ "_" ++ c),
          constructors.fromJust),
        TemplateIdentifier_t,
        context);
  -- If the datatype hasn't been declared, then do nothing
}
| 'template' NonMarkingVarReference_t Datatype_t id::Identifier_t 'with' alloc::Identifier_t 'prefix' pfx::Identifier_c ';'
  { top.ast = templateVarReferenceDecl(fromId(id), fromId(alloc), just(pfx.ast)); }
action {
  local constructors::Maybe<[String]> = lookup(id.lexeme, adtConstructors);
  if (constructors.isJust)
    context =
      addIdentsToScope(
        map(
          \ c::String -> name(pfx.ast.name ++ c),
          constructors.fromJust),
        TemplateIdentifier_t,
        context);
  -- If the datatype hasn't been declared, then do nothing
}
