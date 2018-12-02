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
        proto_typedef unification_trail;
        (unification_trail)0
      }
    end;
  
  e2.env = addEnv(e1.defs, e1.env);
  
  local type::Type = e1.typerep;
  type.otherType = e2.typerep;
  
  local localErrors::[Message] =
    e1.errors ++ e2.errors ++ trail.errors ++
    type.unifyErrors(top.location, addEnv(e2.defs, e2.env)) ++
    checkUnificationHeaderDef("unification_trail", top.location, top.env);
  
  -- Can't use decExpr wrappers here since e1, e2 may recieve an environemnt containing more defs
  -- in the forward.
  local fwrd::Expr = type.unifyProd(e1, e2, trailExpr, top.location);
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production defaultUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  propagate substituted;
  top.pp = pp"unifyDefault(${e1.pp}, ${e2.pp}, ${trail.pp})";
  
  forwards to equalsExpr(e1, e2, location=builtin);
}

abstract production varValUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  propagate substituted;
  top.pp = pp"unifyVarVal(${e1.pp}, ${e2.pp}, ${trail.pp})";
  
  forwards to
    ableC_Expr {
      inst _unify_var_val<$directTypeExpr{e2.typerep}>($Expr{e1}, $Expr{e2}, $Expr{trail})
    };
}

abstract production valVarUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  propagate substituted;
  top.pp = pp"unifyValVar(${e1.pp}, ${e2.pp}, ${trail.pp})";
  
  forwards to
    ableC_Expr {
      ({$directTypeExpr{e1.typerep} _val = $Expr{e1};
        $directTypeExpr{e2.typerep} _var = $Expr{e2};
        inst _unify_var_val<$directTypeExpr{e1.typerep}>(_var, _val, $Expr{trail});})
    };
}

abstract production varVarUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  propagate substituted;
  top.pp = pp"unifyVarVar(${e1.pp}, ${e2.pp}, ${trail.pp})";
  
  local e1SubType::Type = varSubType(e1.typerep);
  forwards to
    ableC_Expr {
      inst _unify_var_var<$directTypeExpr{e1SubType}>($Expr{e1}, $Expr{e2}, $Expr{trail})
    };
}

abstract production adtUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  propagate substituted;
  top.pp = pp"unifyDatatype(${e1.pp}, ${e2.pp}, ${trail.pp})";
  
  local adtLookup::[RefIdItem] =
    case e1.typerep.maybeRefId of
    | just(rid) -> lookupRefId(rid, top.env)
    | nothing() -> []
    end;
  
  local adt::Decorated ADTDecl =
    case adtLookup of
    | adtRefIdItem(adt) :: _ -> adt
    end;
  
  forwards to
    injectGlobalDeclsExpr(
      foldDecl([maybeValueDecl(adt.unifyFnName, decls(adt.unifyTransform))]),
      ableC_Expr {
        $name{adt.unifyFnName}($Expr{e1}, $Expr{e2}, $Expr{trail})
      },
      location=builtin);
}

attribute unifyErrors occurs on ADTDecl, ConstructorList, Constructor, Parameters, ParameterDecl;
synthesized attribute unifyFnName::String occurs on ADTDecl;
synthesized attribute unifyTransform<a>::a;
attribute unifyTransform<Decls> occurs on ADTDecl;

aspect production adtDecl
top::ADTDecl ::= n::Name cs::ConstructorList
{
  top.unifyErrors =
    \ l::Location env::Decorated Env ->
      if null(lookupValue(top.unifyFnName, env))
      then
        case cs.unifyErrors(top.location, addEnv([valueDef(top.unifyFnName, errorValueItem())], env)) of
        | [] -> []
        | m -> [nested(l, s"In unification of datatype ${top.adtGivenName}", m)]
        end
      else [];
  top.unifyFnName = "_unify_" ++ n.name;
  top.unifyTransform =
    ableC_Decls {
      proto_typedef unification_trail;
      static _Bool $name{top.unifyFnName}(
        $BaseTypeExpr{adtTypeExpr} adt1,
        $BaseTypeExpr{adtTypeExpr} adt2,
        unification_trail trail);
      static _Bool $name{top.unifyFnName}(
        $BaseTypeExpr{adtTypeExpr} adt1,
        $BaseTypeExpr{adtTypeExpr} adt2,
        unification_trail trail) {
        return match (adt1, adt2) (
          $ExprClauses{cs.unifyTransform}
          _, _ -> 0;
        );
      }
    };
}

attribute unifyTransform<ExprClauses> occurs on ConstructorList;

aspect production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  top.unifyErrors =
    \ l::Location env::Decorated Env -> c.unifyErrors(l, env) ++ cl.unifyErrors(l, env);
  top.unifyTransform =
    consExprClause(c.unifyTransform, cl.unifyTransform, location=builtin);
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.unifyErrors = \ Location Decorated Env -> [];
  top.unifyTransform = failureExprClause(location=builtin);
}

attribute unifyTransform<ExprClause> occurs on Constructor;

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  top.unifyErrors = ps.unifyErrors;
  top.unifyTransform =
    exprClause(
      consPattern(
        constructorPattern(n, ps.unifyPatterns1, location=builtin),
        consPattern(
          constructorPattern(n, ps.unifyPatterns2, location=builtin),
          nilPattern())),
      ps.unifyTransform,
      location=builtin);
}

synthesized attribute unifyPatterns1::PatternList occurs on Parameters;
synthesized attribute unifyPatterns2::PatternList occurs on Parameters;
attribute unifyTransform<Expr> occurs on Parameters;

aspect production consParameters
top::Parameters ::= h::ParameterDecl t::Parameters
{
  top.unifyErrors =
    \ l::Location env::Decorated Env -> h.unifyErrors(l, env) ++ t.unifyErrors(l, env);
  top.unifyPatterns1 = consPattern(h.unifyPattern1, t.unifyPatterns1);
  top.unifyPatterns2 = consPattern(h.unifyPattern2, t.unifyPatterns2);
  top.unifyTransform =
    andExpr(h.unifyTransform, t.unifyTransform, location=builtin);
}

aspect production nilParameters
top::Parameters ::= 
{
  top.unifyErrors = \ Location Decorated Env -> [];
  top.unifyPatterns1 = nilPattern();
  top.unifyPatterns2 = nilPattern();
  top.unifyTransform = mkIntConst(1, builtin);
}

synthesized attribute unifyPattern1::Pattern occurs on ParameterDecl;
synthesized attribute unifyPattern2::Pattern occurs on ParameterDecl;
attribute unifyTransform<Expr> occurs on ParameterDecl;

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  n::MaybeName  attrs::Attributes
{
  local type::Type = top.typerep;
  type.otherType = type;
  top.unifyErrors = \ Location env::Decorated Env -> type.unifyErrors(top.sourceLocation, env);
  
  local varName1::Name = name(fieldName.name ++ "1", location=builtin);
  local varName2::Name = name(fieldName.name ++ "2", location=builtin);
  top.unifyPattern1 = patternName(varName1, location=builtin);
  top.unifyPattern2 = patternName(varName2, location=builtin);
  top.unifyTransform =
    unifyExpr(
      declRefExpr(varName1, location=builtin),
      declRefExpr(varName2, location=builtin),
      justExpr(ableC_Expr { trail }),
      location=builtin);
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
