grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

abstract production freeVarPattern
top::Pattern ::=
{
  propagate substituted;
  top.pp = pp"freevar";
  top.decls = [];
  top.defs := [];
  top.errors :=
    case top.expectedType.withoutAttributes of
    | extType(_, varType(_)) -> []
    | errorType() -> []
    | _ -> [err(top.location, s"freevar pattern expected to match var reference type (got ${showType(top.expectedType)})")]
    end;
  
  local subType::Type = varSubType(top.expectedType.withoutAttributes);
    
  top.transform =
    ableC_Expr {
      ({template<a> _Bool is_bound();
        !is_bound($Expr{top.transformIn});})
    };
}

abstract production boundVarPattern
top::Pattern ::= p::Pattern
{
  propagate substituted;
  top.pp = pp"?&${p.pp}";
  top.decls = p.decls;
  top.defs := p.defs;
  top.errors := p.errors;
  top.errors <-
    case top.expectedType.withoutAttributes of
    | extType(_, varType(_)) -> []
    | errorType() -> []
    | _ -> [err(p.location, s"Bound var pattern expected to match var reference type (got ${showType(top.expectedType)})")]
    end;
  
  local subType::Type = varSubType(top.expectedType.withoutAttributes);
  p.expectedType = subType;
  
  -- Store the result in a temporary variable since p.transformIn may be used more than once.
  local tempName::String = "_match_var_" ++ toString(genInt());
  p.transformIn = declRefExpr(name(tempName, location=builtin), location=builtin);
  top.transform =
    ableC_Expr {
      ({template<a> _Bool is_bound();
        template<a> _Bool value();
        is_bound($Expr{top.transformIn}) &&
        ({$directTypeExpr{subType} $name{tempName} = value($Expr{top.transformIn});
          $Expr{p.transform};});})
    };
}
