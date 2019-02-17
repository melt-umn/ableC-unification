grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

abstract production freeVarPattern
top::Pattern ::=
{
  propagate substituted;
  top.pp = pp"freevar";
  top.decls = [];
  top.patternDefs := [];
  top.defs := [];
  top.errors :=
    case top.expectedType.withoutAttributes of
    | extType(_, varType(_)) -> []
    | errorType() -> []
    | _ -> [err(top.location, s"freevar pattern expected to match var reference type (got ${showType(top.expectedType)})")]
    end;
  
  local subType::Type = varSubType(top.expectedType.withoutAttributes);
  
  local isBound::Expr =
    ableC_Expr {
      ({template<a> _Bool is_bound();
        !is_bound($Expr{top.transformIn});})
    };
  isBound.env = top.env;
  isBound.returnType = top.returnType;
  top.defs <- isBound.defs;
  
  top.transform = decExpr(isBound, location=builtin);
}

abstract production boundVarPattern
top::Pattern ::= p::Pattern
{
  propagate substituted;
  top.pp = pp"?&${p.pp}";
  top.decls = p.decls;
  top.patternDefs := p.patternDefs;
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
  
  local isBound::Expr =
    ableC_Expr {
      ({template<a> _Bool is_bound();
        is_bound($Expr{top.transformIn});})
    };
  isBound.env = top.env;
  isBound.returnType = nothing();
  top.defs <- isBound.defs;
  
  -- Store the result in a temporary variable since p.transformIn may be used more than once.
  local tempName::String = "_match_var_" ++ toString(genInt());
  local valueDecl::Stmt =
    ableC_Stmt {
      template<a> a value();
      $directTypeExpr{subType} $name{tempName} = value($Expr{top.transformIn});
    };
  valueDecl.env = addEnv(isBound.defs, openScopeEnv(isBound.env));
  valueDecl.returnType = nothing();
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
