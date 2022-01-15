grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

abstract production freeVarPattern
top::Pattern ::=
{
  propagate decls, patternDefs, defs, errors;
  top.pp = pp"freevar";
  top.errors <-
    case top.expectedType.withoutAttributes of
    | extType(_, varType(_)) -> []
    | errorType() -> []
    | _ -> [err(top.location, s"freevar pattern expected to match var reference type (got ${showType(top.expectedType)})")]
    end;
  
  local subType::Type = varSubType(top.expectedType.withoutAttributes);
  
  local isBound::Expr =
    ableC_Expr {
      ({template<typename a> _Bool is_bound();
        !is_bound($Expr{top.transformIn});})
    };
  isBound.env = top.env;
  isBound.controlStmtContext = top.controlStmtContext;
  top.defs <- isBound.defs;
  
  top.transform = decExpr(isBound, location=builtin);
}

abstract production boundVarPattern
top::Pattern ::= p::Pattern
{
  propagate decls, patternDefs, defs, errors;
  top.pp = pp"?&${p.pp}";
  top.errors <-
    case top.expectedType.withoutAttributes of
    | extType(_, varType(_)) -> []
    | errorType() -> []
    | _ -> [err(p.location, s"Bound var pattern expected to match var reference type (got ${showType(top.expectedType)})")]
    end;
  
  local subType::Type = varSubType(top.expectedType.withoutAttributes);
  p.expectedType = subType;
  
  local isBound::Expr =
    ableC_Expr {
      ({template<typename a> _Bool is_bound();
        is_bound($Expr{top.transformIn});})
    };
  isBound.env = top.env;
  isBound.controlStmtContext = initialControlStmtContext;
  top.defs <- isBound.defs;
  
  -- Store the result in a temporary variable since p.transformIn may be used more than once.
  local tempName::String = "_match_var_" ++ toString(genIntT());
  local valueDecl::Stmt =
    ableC_Stmt {
      template<typename a> a value();
      $directTypeExpr{subType} $name{tempName} = value($Expr{top.transformIn});
    };
  valueDecl.env = addEnv(isBound.defs, openScopeEnv(isBound.env));
  valueDecl.controlStmtContext = initialControlStmtContext;
  top.defs <- valueDecl.defs;
  
  p.env = addEnv(valueDecl.defs, valueDecl.env);
  
  p.transformIn = declRefExpr(name(tempName, location=builtin), location=builtin);
  top.transform =
    ableC_Expr {
      $Expr{decExpr(isBound, location=builtin)} &&
        ({$Stmt{decStmt(valueDecl)}
          $Expr{p.transform};})
    };
}
