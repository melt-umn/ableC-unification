grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

abstract production freeVarPattern
top::Pattern ::=
{
  propagate errors;
  top.pp = pp"freevar";
  top.errors <-
    case top.expectedType.withoutAttributes of
    | extType(_, varType(_)) -> []
    | errorType() -> []
    | _ -> [err(top.location, s"freevar pattern expected to match var reference type (got ${showType(top.expectedType)})")]
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
  top.pp = pp"?&${p.pp}";
  top.errors <-
    case top.expectedType.withoutAttributes of
    | extType(_, varType(_)) -> []
    | errorType() -> []
    | _ -> [err(p.location, s"Bound var pattern expected to match var reference type (got ${showType(top.expectedType)})")]
    end;
  
  local subType::Type = varSubType(top.expectedType.withoutAttributes);
  p.expectedType = subType;

  top.patternDecls = @p.patternDecls;
  
  -- Store the result in a temporary variable since p.transformIn may be used more than once.
  local tempName::String = "_match_var_" ++ toString(genInt());
  local valueDecl::Stmt =
    ableC_Stmt {
      template<typename a> a value();
      $directTypeExpr{subType} $name{tempName} = value($Expr{top.transformIn});
    };
  valueDecl.env = addEnv(isBound.defs, openScopeEnv(isBound.env));
  valueDecl.controlStmtContext = initialControlStmtContext;
  top.defs <- valueDecl.defs;
  
  p.env = addEnv(valueDecl.defs, valueDecl.env);

  top.patternDecls = @p.patternDecls;
  
  p.transformIn = declRefExpr(name(tempName, location=builtin), location=builtin);
  top.transform =
    ableC_Expr {
      ({template<typename a> _Bool is_bound();
        template<typename a> a value();
        is_bound($Expr{top.transformIn}) &&
        ({$directTypeExpr{subType} $name{tempName} = value($Expr{top.transformIn});
          $Expr{@p.transform};});})
    };
}
