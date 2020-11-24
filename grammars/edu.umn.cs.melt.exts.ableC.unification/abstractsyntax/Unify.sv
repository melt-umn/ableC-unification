grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

abstract production unifyExpr
top::Expr ::= e1::Expr e2::Expr trail::MaybeExpr
{
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
  
  local tmpName1::Name = name("_tmp" ++ toString(genInt()), location=builtin);
  local tmpName2::Name = name("_tmp" ++ toString(genInt()), location=builtin);
  
  local dcls::Stmt =
    ableC_Stmt {
      $Decl{autoDecl(tmpName1, e1)}
      $Decl{autoDecl(tmpName2, e2)}
    };
  dcls.env = top.env;
  dcls.returnType = top.returnType;
  
  local decE1::Decorated Expr =
    case dcls of
    | seqStmt(declStmt(autoDecl(_, e1)), _) -> e1
    end;
  local decE2::Decorated Expr =
    case dcls of
    | seqStmt(_, declStmt(autoDecl(_, e2))) -> e2
    end;
  
  local type::Type = decE1.typerep.defaultFunctionArrayLvalueConversion;
  type.otherType = decE2.typerep.defaultFunctionArrayLvalueConversion;
  
  local localErrors::[Message] =
    decE1.errors ++ decE2.errors ++ trail.errors ++
    type.unifyErrors(top.location, addEnv(dcls.defs, dcls.env)) ++
    checkUnificationHeaderDef("unification_trail", top.location, top.env);
  
  local fwrd::Expr =
    case decE1.isSimple, decE2.isSimple, dcls of
    | true, true, _ -> type.unifyProd(e1, e2, trailExpr, top.location)
    | true, false, seqStmt(_, d) ->
      stmtExpr(
        decStmt(d),
        type.unifyProd(e1, declRefExpr(tmpName2, location=builtin), trailExpr, top.location),
        location=builtin)
    | false, true, seqStmt(d, _) ->
      stmtExpr(
        decStmt(d),
        type.unifyProd(declRefExpr(tmpName1, location=builtin), e2, trailExpr, top.location),
        location=builtin)
    | false, false, _ ->
      stmtExpr(
        decStmt(dcls),
        type.unifyProd(
          declRefExpr(tmpName1, location=builtin),
          declRefExpr(tmpName2, location=builtin),
          trailExpr, top.location),
        location=builtin)
    end;
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production defaultUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  top.pp = pp"unifyDefault(${e1.pp}, ${e2.pp}, ${trail.pp})";
  
  forwards to equalsExpr(e1, e2, location=builtin);
}

abstract production varValUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  top.pp = pp"unifyVarVal(${e1.pp}, ${e2.pp}, ${trail.pp})";
  
  forwards to
    ableC_Expr {
      inst _unify_var_val<$directTypeExpr{e2.typerep}>($Expr{e1}, $Expr{e2}, $Expr{trail})
    };
}

abstract production valVarUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  top.pp = pp"unifyValVar(${e1.pp}, ${e2.pp}, ${trail.pp})";
  
  forwards to
    ableC_Expr {
      inst _unify_var_val<$directTypeExpr{e1.typerep}>($Expr{e2}, $Expr{e1}, $Expr{trail})
    };
}

abstract production varVarUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  top.pp = pp"unifyVarVar(${e1.pp}, ${e2.pp}, ${trail.pp})";
  
  local e1SubType::Type = varSubType(e1.typerep);
  forwards to
    ableC_Expr {
      inst _unify_var_var<$directTypeExpr{e1SubType}>($Expr{e1}, $Expr{e2}, $Expr{trail})
    };
}

synthesized attribute unifyFnName::String;
synthesized attribute unifyTransform<a>::a;

abstract production structUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  top.pp = pp"unifyStruct(${e1.pp}, ${e2.pp}, ${trail.pp})";
  
  local structLookup::[RefIdItem] =
    case e1.typerep.maybeRefId of
    | just(rid) -> lookupRefId(rid, top.env)
    | nothing() -> []
    end;
  
  local struct::Decorated StructDecl =
    case structLookup of
    | structRefIdItem(struct) :: _ -> struct
    end;
  
  forwards to
    injectGlobalDeclsExpr(
      foldDecl([maybeValueDecl(struct.unifyFnName, decls(struct.unifyTransform))]),
      ableC_Expr {
        $name{struct.unifyFnName}($Expr{e1}, $Expr{e2}, $Expr{trail})
      },
      location=builtin);
}

attribute unifyErrors occurs on StructDecl, StructItemList, StructItem, StructDeclarators, StructDeclarator;
attribute unifyFnName occurs on StructDecl;
attribute unifyTransform<Decls> occurs on StructDecl;

aspect production structDecl
top::StructDecl ::= attrs::Attributes  name::MaybeName  dcls::StructItemList
{
  local n::String = name.maybename.fromJust.name;
  top.unifyErrors =
    \ l::Location env::Decorated Env ->
      if !name.maybename.isJust
      then [err(l, "Cannot unify anonymous struct")]
      else if null(lookupValue(top.unifyFnName, env))
      then
        case dcls.unifyErrors(top.location, addEnv([valueDef(top.unifyFnName, errorValueItem())], env)) of
        | [] -> []
        | m -> [nested(l, s"In unification of struct ${n}", m)]
        end
      else [];
  top.unifyFnName = "_unify_" ++ n;
  top.unifyTransform =
    ableC_Decls {
      proto_typedef unification_trail;
      static _Bool $name{top.unifyFnName}(
        struct $name{n} s1,
        struct $name{n} s2,
        unification_trail trail);
      static _Bool $name{top.unifyFnName}(
        struct $name{n} s1,
        struct $name{n} s2,
        unification_trail trail) {
        return $Expr{dcls.unifyTransform};
      }
    };
}

attribute unifyTransform<Expr> occurs on StructItemList, StructItem, StructDeclarators, StructDeclarator;

aspect production consStructItem
top::StructItemList ::= h::StructItem  t::StructItemList
{
  top.unifyErrors =
    \ l::Location env::Decorated Env -> h.unifyErrors(l, env) ++ t.unifyErrors(l, env);
  top.unifyTransform =
    andExpr(h.unifyTransform, t.unifyTransform, location=builtin);
}
aspect production nilStructItem
top::StructItemList ::=
{
  top.unifyErrors = \ l::Location env::Decorated Env -> [];
  top.unifyTransform = mkIntConst(1, builtin);
}

aspect production structItem
top::StructItem ::= attrs::Attributes  ty::BaseTypeExpr  dcls::StructDeclarators
{
  top.unifyErrors = dcls.unifyErrors;
  top.unifyTransform = dcls.unifyTransform;
}
aspect production structItems
top::StructItem ::= dcls::StructItemList
{
  top.unifyErrors = dcls.unifyErrors;
  top.unifyTransform = dcls.unifyTransform;
}
aspect production anonStructStructItem
top::StructItem ::= d::StructDecl
{
  -- TODO?
  top.unifyErrors =
    \ l::Location env::Decorated Env ->
      [err(d.location, "Unification is not yet supported for anonymous structs")];
  top.unifyTransform = error("Undefined, should have raised an error");
}
aspect production anonUnionStructItem
top::StructItem ::= d::UnionDecl
{
  top.unifyErrors =
    \ l::Location env::Decorated Env ->
      [err(d.location, "Unification is not defined for unions")];
  top.unifyTransform = error("Undefined, should have raised an error");
}
aspect production warnStructItem
top::StructItem ::= msg::[Message]
{
  top.unifyErrors = \ l::Location env::Decorated Env -> [];
  top.unifyTransform = mkIntConst(1, builtin);
}

aspect production consStructDeclarator
top::StructDeclarators ::= h::StructDeclarator  t::StructDeclarators
{
  top.unifyErrors =
    \ l::Location env::Decorated Env -> h.unifyErrors(l, env) ++ t.unifyErrors(l, env);
  top.unifyTransform =
    andExpr(h.unifyTransform, t.unifyTransform, location=builtin);
}
aspect production nilStructDeclarator
top::StructDeclarators ::=
{
  top.unifyErrors = \ l::Location env::Decorated Env -> [];
  top.unifyTransform = mkIntConst(1, builtin);
}

aspect production structField
top::StructDeclarator ::= name::Name  ty::TypeModifierExpr  attrs::Attributes
{
  local type::Type = top.typerep;
  type.otherType = type;
  top.unifyErrors = \ Location env::Decorated Env -> type.unifyErrors(top.sourceLocation, env);
  top.unifyTransform =
    unifyExpr(
      ableC_Expr { s1.$Name{name} },
      ableC_Expr { s2.$Name{name} },
      justExpr(ableC_Expr { trail }),
      location=builtin);
}
aspect production structBitfield
top::StructDeclarator ::= name::MaybeName  ty::TypeModifierExpr  e::Expr  attrs::Attributes
{
  local type::Type = top.typerep;
  type.otherType = type;
  top.unifyErrors = \ Location env::Decorated Env -> type.unifyErrors(top.sourceLocation, env);
  top.unifyTransform =
    case name of
    | justName(n) ->
      unifyExpr(
        ableC_Expr { s1.$Name{n} },
        ableC_Expr { s2.$Name{n} },
        justExpr(ableC_Expr { trail }),
        location=builtin)
    | nothingName() -> mkIntConst(1, builtin) -- Ignore anonymous padding bits
    end;
}
aspect production warnStructField
top::StructDeclarator ::= msg::[Message]
{
  top.unifyErrors = \ Location env::Decorated Env -> [];
  top.unifyTransform = mkIntConst(1, builtin);
}

abstract production adtUnifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
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
attribute unifyFnName occurs on ADTDecl;
attribute unifyTransform<Decls> occurs on ADTDecl;

aspect production adtDecl
top::ADTDecl ::= attrs::Attributes n::Name cs::ConstructorList
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
