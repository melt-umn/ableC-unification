grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

abstract production freeVarPattern
top::Pattern ::=
{
  propagate errors;
  attachNote extensionGenerated("ableC-unification");
  top.pp = pp"freevar";
  top.errors <-
    case top.expectedType.withoutAttributes of
    | extType(_, varType(_)) -> []
    | errorType() -> []
    | _ -> [errFromOrigin(top, s"freevar pattern expected to match var reference type (got ${showType(top.expectedType)})")]
    end;
  
  local subType::Type = varSubType(top.expectedType.withoutAttributes);
  
  top.transform =
    ableC_Expr {
      ({template<typename a> _Bool is_bound();
        !is_bound($Expr{top.transformIn});})
    };
}

abstract production boundVarPattern
top::Pattern ::= p::Pattern
{
  propagate initialEnv, errors;
  attachNote extensionGenerated("ableC-unification");
  top.pp = pp"?&${p.pp}";
  top.errors <-
    case top.expectedType.withoutAttributes of
    | extType(_, varType(_)) -> []
    | errorType() -> []
    | _ -> [errFromOrigin(p, s"Bound var pattern expected to match var reference type (got ${showType(top.expectedType)})")]
    end;
  
  local subType::Type = varSubType(top.expectedType.withoutAttributes);
  p.expectedType = subType;

  top.patternDecls = @p.patternDecls;
  
  -- Store the result in a temporary variable since p.transformIn may be used more than once.
  local tempName::String = "_match_var_" ++ toString(genInt());
  p.transformIn = declRefExpr(name(tempName));
  top.transform =
    ableC_Expr {
      ({template<typename a> _Bool is_bound();
        template<typename a> a value();
        is_bound($Expr{top.transformIn}) &&
        ({$directTypeExpr{subType} $name{tempName} = value($Expr{top.transformIn});
          $Expr{@p.transform};});})
    };
}
