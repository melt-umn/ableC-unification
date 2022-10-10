grammar edu:umn:cs:melt:exts:ableC:unification:concretesyntax:unification;

marking terminal VarType_t '?' lexer classes {Operator};

concrete productions top::Pointer_c
| '?'
    { top.ast = varTypeExpr(nilQualifier(), top.givenType, top.location); }
| '?'  q::InitiallyUnattributedTypeQualifierList_c
    { top.ast = varTypeExpr(q.typeQualifiers, top.givenType, top.location); }
| '?'  t::Pointer_c
    { t.givenType = varTypeExpr(nilQualifier(), top.givenType, top.location);
      top.ast = t.ast; }
| '?'  q::InitiallyUnattributedTypeQualifierList_c  t::Pointer_c
    { t.givenType = varTypeExpr(q.typeQualifiers, top.givenType, top.location);
      top.ast = t.ast; }

-- See ableC/grammars/edu.umn.cs.melt.ableC/concretesyntax/gcc_exts/Declarations.sv
-- We can't directly resolve the ambigutiy with attributes in the qualifier list using precedence since '?' is a marking terminal.
-- Instead, define a new nonterminal for lists of type qualifiers that can't start with attributes:
closed nonterminal InitiallyUnattributedTypeQualifierList_c with location, typeQualifiers, mutateTypeSpecifiers, specialSpecifiers, attributes;
concrete productions top::InitiallyUnattributedTypeQualifierList_c
| h::TypeQualifier_c
  operator=CPP_Attr_LowerPrec_t
    { top.typeQualifiers = h.typeQualifiers;
      top.mutateTypeSpecifiers = h.mutateTypeSpecifiers;
      top.specialSpecifiers = [];
      top.attributes = nilAttribute(); }
| h::TypeQualifier_c  t::TypeQualifierList_c
    { top.typeQualifiers = qualifierCat(h.typeQualifiers, t.typeQualifiers);
      top.mutateTypeSpecifiers = h.mutateTypeSpecifiers ++ t.mutateTypeSpecifiers;
      top.specialSpecifiers = t.specialSpecifiers;
      top.attributes = t.attributes; }
