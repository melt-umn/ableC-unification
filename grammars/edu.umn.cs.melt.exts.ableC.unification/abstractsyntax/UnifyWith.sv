grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

abstract production unifyWithDecl
top::Decl ::= ty::TypeName  func::Name
{
  top.pp = pp"unify ${ty.pp} with ${func.pp};";
  propagate env, controlStmtContext;

  nondecorated local fnType::Type = func.valueItem.typerep;
  local unificationTrailTypes::[ValueItem] = lookupValue("unification_trail", top.env);
  nondecorated local expectedFnType::Type =
    functionType(builtinType(nilQualifier(), boolType()),
      protoFunctionType([ty.typerep, ty.typerep,
                         head(unificationTrailTypes).typerep],
                        false),
      nilQualifier());
  local type::Type = ty.typerep.defaultFunctionArrayLvalueConversion;
  local localErrors::[Message] = type.errors ++
    checkUnificationHeaderDef(top.env) ++
    func.valueLookupCheck ++
    case getCustomUnify(^type, ^type, top.env) of
    | just(_) -> [errFromOrigin(func,
                      show(80, pp"unify for ${ty.pp} already defined"))]
    | nothing() -> []
    end ++
    if !null(unificationTrailTypes) && !compatibleTypes(fnType, expectedFnType, false, false)
    then [errFromOrigin(func, s"unify function for ${show(80, ^type)} must have type ${show(80, expectedFnType)} (got ${show(80, fnType)})")]
    else [];
  forwards to
    if null(localErrors)
      then defsDecl([customUnifyDef(^type, ^func)])
      else warnDecl(localErrors);
}
