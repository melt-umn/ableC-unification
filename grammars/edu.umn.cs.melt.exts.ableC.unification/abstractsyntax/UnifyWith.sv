grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

abstract production unifyWithDecl
top::Decl ::= ty::TypeName  func::Name
{
  top.pp = pp"unify ${ty.pp} with ${func.pp};";
  propagate env, controlStmtContext;

  local fnType::Type = func.valueItem.typerep;
  local unificationTrailTypes::[ValueItem] = lookupValue("unification_trail", top.env);
  local expectedFnType::Type =
    functionType(builtinType(nilQualifier(), boolType()),
      protoFunctionType([ty.typerep, ty.typerep,
                         head(unificationTrailTypes).typerep],
                        false),
      nilQualifier());
  local type::Type = ty.typerep.defaultFunctionArrayLvalueConversion;
  local localErrors::[Message] = type.errors ++
    checkUnificationHeaderDef("unification_trail", func.location, top.env) ++
    func.valueLookupCheck ++
    case getCustomUnify(type, type, top.env) of
    | just(_) -> [err(func.location,
                      show(80, pp"unify for ${ty.pp} already defined"))]
    | nothing() -> []
    end ++
    if !null(unificationTrailTypes) && !compatibleTypes(fnType, expectedFnType, false, false)
    then [err(func.location, s"unify function for ${showType(type)} must have type ${showType(expectedFnType)} (got ${showType(fnType)})")]
    else [];
  forwards to
    if null(localErrors)
      then defsDecl([customUnifyDef(type, func)])
      else warnDecl(localErrors);
}
