grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

abstract production unifyWithDecl
top::Decl ::= ty::TypeName  unifyName::Name
{
  top.pp = pp"unify ${ty.pp} with ${unifyName.pp};";
  local type::Type = ty.typerep.defaultFunctionArrayLvalueConversion;
  local localErrors::[Message] = type.errors ++
    case getCustomUnify(type, top.env) of
    | just(_) -> [err(unifyName.location,
                      show(80, pp"unify for ${ty.pp} already defined"))]
    | nothing() -> []
    end;
  forwards to
    if null(localErrors)
      then defsDecl([customUnifyDef(type.mangledName, unifyName)])
      else warnDecl(localErrors);
}
