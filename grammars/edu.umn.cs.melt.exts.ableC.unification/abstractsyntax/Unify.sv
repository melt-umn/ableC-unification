grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

abstract production unifyExpr
top::Expr ::= e1::Expr e2::Expr trail::MaybeExpr
{
  propagate substituted;
  top.pp = pp"unify(${e1.pp}, ${e2.pp}${if trail.isJust then pp", ${trail.pp}" else notext()})";
  
  local trailExpr::Expr =
    case trail of
    | justExpr(e) -> e
    | nothingExpr() ->
      ableC_Expr {
        proto_typedef unification_trail_t;
        (unification_trail_t)0
      }
    end;
  
  local lType::Type = e1.typerep;
  lType.otherType = rType;
  local rType::Type = e2.typerep;
  rType.otherType = lType;
  
  local localErrors::[Message] =
    checkUnificationHeaderDef("unification_trail_t", top.location, top.env);
  
  local fwrd::Expr =
    fromMaybe(
      defaultUnifyExpr(_, _, _, location=_),
      orElse(lType.lUnifyProd, rType.rUnifyProd))(e1, e2, trailExpr, top.location);
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production defaultUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  propagate substituted;
  top.pp = pp"unify(${e1.pp}, ${e2.pp}, ${trail.pp})";
  
  -- TODO: Error checking - e1 and e2 should be equality types
  local localErrors::[Message] =
    case e1.typerep, e2.typerep of
    | errorType(), _ -> []
    | _, errorType() -> []
    | t1, t2 ->
      if compatibleTypes(t1, t2, false, false)
      then []
      else [err(e1.location, s"unify value types must match (got ${showType(t1)}, ${showType(t2)})")]
    end;
  local fwrd::Expr = equalsExpr(e1, e2, location=builtin);
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production varValUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  propagate substituted;
  top.pp = pp"unify(${e1.pp}, ${e2.pp}, ${trail.pp})";
  local localErrors::[Message] =
    case e1.typerep of
    | extType(_, varType(sub)) ->
      if compatibleTypes(sub, e2.typerep, false, false)
      then []
      else [err(e1.location, s"unify variable and value types must match (got ${showType(sub)}, ${showType(e2.typerep)})")]
    | t -> [err(e1.location, s"unify expected a variable type (got ${showType(t)})")]
    end ++
    checkUnificationHeaderTemplateDef("_unify_var_val", top.location, top.env);
  
  local fwrd::Expr =
    ableC_Expr {
      inst _unify_var_val<$directTypeExpr{e2.typerep}>($Expr{e1}, $Expr{e2}, $Expr{trail})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production valVarUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  propagate substituted;
  top.pp = pp"unify(${e1.pp}, ${e2.pp}, ${trail.pp})";
  local localErrors::[Message] =
    case e2.typerep of
    | extType(_, varType(sub)) ->
      if compatibleTypes(sub, e2.typerep, false, false)
      then []
      else [err(e1.location, s"unify variable and value types must match (got ${showType(e1.typerep)}, ${showType(sub)})")]
    | t -> [err(e1.location, s"unify expected a variable type (got ${showType(t)})")]
    end ++
    checkUnificationHeaderTemplateDef("_unify_var_val", top.location, top.env);
  
  local fwrd::Expr =
    ableC_Expr {
      ({$directTypeExpr{e1.typerep} _val = $Expr{e1};
        $directTypeExpr{e2.typerep} _var = $Expr{e2};
        inst _unify_var_val<$directTypeExpr{e1.typerep}>(_var, _val, $Expr{trail});})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production varVarUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  propagate substituted;
  top.pp = pp"unify(${e1.pp}, ${e2.pp}, ${trail.pp})";
  local localErrors::[Message] =
    case e1.typerep, e2.typerep of
    | extType(_, varType(sub1)), extType(_, varType(sub2)) ->
      if compatibleTypes(sub1, sub2, false, false)
      then []
      else [err(e1.location, s"unify variable types must match (got ${showType(sub1)}, ${showType(sub2)})")]
    | t1, t2 -> [err(e1.location, s"unify expected variable types (got ${showType(t1)}, ${showType(t2)})")]
    end ++
    checkUnificationHeaderTemplateDef("_unify_var_var", top.location, top.env);
  
  local e1SubType::Type = varSubType(e1.typerep);
  local fwrd::Expr =
    ableC_Expr {
      inst _unify_var_var<$directTypeExpr{e1SubType}>($Expr{e1}, $Expr{e2}, $Expr{trail})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

-- Check the given env for the given value name
function checkUnificationHeaderDef
[Message] ::= n::String loc::Location env::Decorated Env
{
  return
    if !null(lookupValue(n, env))
    then []
    else [err(loc, "Missing include of unification.xh")];
}
-- Check the given env for the given template name
function checkUnificationHeaderTemplateDef
[Message] ::= n::String loc::Location env::Decorated Env
{
  return
    if !null(lookupTemplate(n, env))
    then []
    else [err(loc, "Missing include of unification.xh")];
}
