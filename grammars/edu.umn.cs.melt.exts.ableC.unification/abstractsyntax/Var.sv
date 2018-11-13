grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

import edu:umn:cs:melt:ableC:abstractsyntax:overloadable;

abstract production newVarExpr
top::Expr ::= ty::TypeName init::MaybeExpr
{
  propagate substituted;
  top.pp = pp"newvar<${ty.pp}>(${init.pp})";
  
  local localErrors::[Message] =
    ty.errors ++ init.errors ++
    (if !ty.typerep.isCompleteType(top.env)
     then [err(top.location, s"var type parameter has incomplete type ${showType(ty.typerep)}")]
     else []) ++
    case init of
    | justExpr(e) ->
      if compatibleTypes(e.typerep, ty.typerep, false, false)
      then []
      else [err(e.location, s"newvar expected initial value of type ${showType(e.typerep)} (got ${showType(ty.typerep)})")]
    | nothingExpr() -> []
    end ++
    checkUnificationHeaderTemplateDef("_var_d", top.location, top.env);
  
  local fwrd::Expr =
    ableC_Expr {
      proto_typedef _var_d;
      ({inst _var_d<$TypeName{ty}> *_result =
          alloca(sizeof(inst _var_d<$directTypeExpr{ty.typerep}>));
        *_result = $Expr{
          case init of
          | nothingExpr() ->
            ableC_Expr { inst _Free<$directTypeExpr{ty.typerep}>() }
          | justExpr(e) ->
            ableC_Expr { inst _Bound<$directTypeExpr{ty.typerep}>($Expr{e}) }
          end};
        ($TypeName{
           typeName(
             directTypeExpr(ty.typerep),
             varTypeExpr(nilQualifier(), baseTypeExpr(), builtin))})_result;})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production varRefExpr
top::Expr ::= e::Expr
{
  propagate substituted;
  top.pp = pp"?&(${e.pp})";
  
  local subType::Type = varSubType(e.typerep);
  local localErrors::[Message] =
    e.errors ++
    (if !subType.isCompleteType(top.env)
     then [err(top.location, s"var type parameter has incomplete type ${showType(subType)}")]
     else []) ++
    checkUnificationHeaderTemplateDef("_var_d", top.location, top.env);
  
  local fwrd::Expr =
    newVarExpr(
      typeName(directTypeExpr(e.typerep), baseTypeExpr()),
      justExpr(e),
      location=builtin);
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production showVar
top::Expr ::= e::Expr
{
  propagate substituted;
  top.pp = pp"show(${e.pp})";
  
  local subType::Type = varSubType(e.typerep);
  local localErrors::[Message] =
    (if !subType.isCompleteType(top.env)
     then [err(top.location, s"var type parameter has incomplete type ${showType(subType)}")]
     else []) ++
    checkUnificationHeaderTemplateDef("show_var", top.location, top.env);
  
  local fwrd::Expr =
    ableC_Expr { inst show_var<$directTypeExpr{subType}>($Expr{e}) };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}
