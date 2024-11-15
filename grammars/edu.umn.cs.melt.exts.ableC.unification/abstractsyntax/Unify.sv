grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

aspect function getInitialEnvDefs
[Def] ::=
{
  d <-
    [valueDef(
       "unify",
       builtinFunctionValueItem(
         functionType(builtinType(nilQualifier(), boolType()), noProtoFunctionType(), nilQualifier()),
         unifyCallExpr))];
}

abstract production unifyCallExpr implements ReferenceCall
top::Expr ::= f::Name a::Exprs
{
  top.pp = pp"${f.pp}(${ppImplode(pp", ", a.pps)})";
  forwards to bindDirectCallExpr(@f, @a,
    case a.bindRefExprs of
    | [e1, e2] -> unifyExpr(e1, e2, nothing())
    | [e1, e2, t] -> unifyExpr(e1, e2, just(t))
    | _ -> errorExpr(errFromOrigin(top, s"${f.name} expected 2 or 3 arguments, got ${toString(a.count)}") :: a.errors)
    end);
}

abstract production unifyExpr
top::Expr ::= e1::Expr e2::Expr trail::Maybe<Expr>
{
  top.pp = pp"unify(${ppImplode(pp", ", [e1.pp, e2.pp] ++ case trail of just(t) -> [t.pp] | nothing() -> [] end)})";
  attachNote extensionGenerated("ableC-unification");

  local trailExpr::Expr =
    case trail of
    | just(e) -> e
    | nothing() ->
      ableC_Expr {
        proto_typedef unification_trail;
        (unification_trail)0
      }
    end;
  
  local type1::Type = e1.typerep.defaultFunctionArrayLvalueConversion;
  local type2::Type = e2.typerep.defaultFunctionArrayLvalueConversion;
  type1.otherType = ^type2;

  nondecorated local trailExpectedType::Type =
    case lookupValue("unification_trail", top.env) of
    | v :: _ -> v.typerep
    | _ -> errorType()
    end;
  
  local localErrors::[Message] =
    e1.errors ++ e2.errors ++ trailExpr.errors ++
    unifyErrors(impl.env, ^type1, ^type2) ++
    (if !trail.isJust || typeAssignableTo(trailExpectedType, trailExpr.typerep) then []
     else [errFromOrigin(trailExpr, s"Trail must have type unification_trail (got ${show(80, trailExpr.typerep)})")]) ++
    checkUnificationHeaderDef(top.env);
  
  local prod::Unify =
    case getCustomUnify(^type1, ^type2, top.env) of
    | just(fn) -> customUnifyExpr(fn)
    | nothing() -> type1.unifyProd
    end;

  nondecorated local tmp1::Name = freshName("u1");
  nondecorated local tmp2::Name = freshName("u2");
  nondecorated local tmpTrail::Name = freshName("trail");
  forward fwrd = letExpr(
    consDecl(
      bindExprDecl(tmp1, @e1),
      consDecl(
        bindExprDecl(tmp2, @e2),
        consDecl(
          bindExprDecl(tmpTrail, @trailExpr),
          nilDecl()))),
          @impl);
  local impl::Expr = prod(e1.bindRefExpr, e2.bindRefExpr, trailExpr.bindRefExpr);
  
  forwards to if null(localErrors) then @fwrd else errorExpr(localErrors);
}

function unifyErrors
[Message] ::= env::Env  t1::Type  t2::Type
{
  t1.otherType = ^t2;
  return case getCustomUnify(^t1, ^t2, env) of
  | just(_) -> []
  | nothing() -> t1.unifyErrors(env)
  end;
}

dispatch Unify = Expr ::= e1::Expr e2::Expr trail::Expr;

abstract production defaultUnifyExpr implements Unify
top::Expr ::= e1::Expr e2::Expr trail::Expr
{
  top.pp = pp"unifyDefault(${e1.pp}, ${e2.pp}, ${trail.pp})";
  attachNote extensionGenerated("ableC-unification");
  
  forwards to equalsExpr(@e1, @e2);
}

abstract production customUnifyExpr implements Unify
top::Expr ::= e1::Expr e2::Expr trail::Expr fn::Name
{
  top.pp = pp"unifyCustom(${fn}, ${e1.pp}, ${e2.pp}, ${trail.pp})";
  attachNote extensionGenerated("ableC-unification");
  
  forwards to
    ableC_Expr {
      $Name{@fn}($Expr{@e1}, $Expr{@e2}, $Expr{@trail})
    };
}

abstract production customTemplateUnifyExpr implements Unify
top::Expr ::= e1::Expr e2::Expr trail::Expr fn::Name ty::Type
{
  top.pp = pp"unifyCustom(${fn}, ${ty.lpp}${ty.rpp}, ${e1.pp}, ${e2.pp}, ${trail.pp})";
  attachNote extensionGenerated("ableC-unification");
  
  nondecorated local targ::TypeName = typeName(ty.baseTypeExpr, ty.typeModifierExpr);
  forwards to
    ableC_Expr {
      inst $Name{@fn}<$TypeName{targ}>($Expr{@e1}, $Expr{@e2}, $Expr{@trail})
    };
}

abstract production varValUnifyExpr implements Unify
top::Expr ::= e1::Expr e2::Expr trail::Expr type::Type
{
  top.pp = pp"unifyVarVal(${e1.pp}, ${e2.pp}, ${trail.pp})";
  attachNote extensionGenerated("ableC-unification");
  
  forwards to
    ableC_Expr {
      inst _unify_var_val<$directTypeExpr{^type}>($Expr{@e1}, $Expr{@e2}, $Expr{@trail})
    };
}

abstract production valVarUnifyExpr implements Unify
top::Expr ::= e1::Expr e2::Expr trail::Expr type::Type
{
  top.pp = pp"unifyValVar(${e1.pp}, ${e2.pp}, ${trail.pp})";
  attachNote extensionGenerated("ableC-unification");

  forwards to
    ableC_Expr {
      inst _unify_var_val<$directTypeExpr{^type}>($Expr{@e2}, $Expr{@e1}, $Expr{@trail})
    };
}

abstract production varVarUnifyExpr implements Unify
top::Expr ::= e1::Expr e2::Expr trail::Expr type::Type
{
  top.pp = pp"unifyVarVar(${e1.pp}, ${e2.pp}, ${trail.pp})";
  attachNote extensionGenerated("ableC-unification");

  forwards to
    ableC_Expr {
      inst _unify_var_var<$directTypeExpr{^type}>($Expr{@e1}, $Expr{@e2}, $Expr{@trail})
    };
}

synthesized attribute unifyFnName::String;
synthesized attribute unifyTransform<a>::a;

abstract production structUnifyExpr implements Unify
top::Expr ::= e1::Expr e2::Expr trail::Expr refId::String
{
  top.pp = pp"unifyStruct(${e1.pp}, ${e2.pp}, ${trail.pp}, ${refId})";
  attachNote extensionGenerated("ableC-unification");
  
  local struct::Decorated StructDecl =
    case lookupRefId(refId, top.env) of
    | structRefIdItem(struct) :: _ -> struct
    | _ -> error("struct demanded when not an structRefIdItem")
    end;
  
  forwards to
    injectGlobalDeclsExpr(
      foldDecl([maybeValueDecl(struct.unifyFnName, decls(struct.unifyTransform))]),
      ableC_Expr {
        $name{struct.unifyFnName}($Expr{@e1}, $Expr{@e2}, $Expr{@trail})
      });
}

attribute unifyErrors occurs on StructDecl, StructItemList, StructItem, StructDeclarators, StructDeclarator;
attribute unifyFnName occurs on StructDecl;
attribute unifyTransform<Decls> occurs on StructDecl;

aspect production structDecl
top::StructDecl ::= attrs::Attributes  name::MaybeName  dcls::StructItemList
{
  attachNote extensionGenerated("ableC-unification");
  local n::String = name.maybename.fromJust.name;
  top.unifyErrors =
    \ env::Env ->
      if !name.maybename.isJust
      then [errFromOrigin(ambientOrigin(), "Cannot unify anonymous struct")]
      else if null(lookupValue(top.unifyFnName, env))
      then
        case attachNote logicalLocationFromOrigin(top) on dcls.unifyErrors(addEnv([valueDef(top.unifyFnName, errorValueItem())], env)) end of
        | [] -> []
        | m -> [nested(getParsedOriginLocationOrFallback(ambientOrigin()), s"In unification of struct ${n}", m)]
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
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ env::Env -> h.unifyErrors(env) ++ t.unifyErrors(env);
  top.unifyTransform = andExpr(h.unifyTransform, t.unifyTransform);
}
aspect production nilStructItem
top::StructItemList ::=
{
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ env::Env -> [];
  top.unifyTransform = mkIntConst(1);
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
  top.unifyErrors = \ _ -> [errFromOrigin(d, "Unification is not yet supported for anonymous structs")];
  top.unifyTransform = error("Undefined, should have raised an error");
}
aspect production anonUnionStructItem
top::StructItem ::= d::UnionDecl
{
  top.unifyErrors = \ _ -> [errFromOrigin(d, "Unification is not defined for unions")];
  top.unifyTransform = error("Undefined, should have raised an error");
}
aspect production warnStructItem
top::StructItem ::= msg::[Message]
{
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ _ -> [];
  top.unifyTransform = mkIntConst(1);
}

aspect production consStructDeclarator
top::StructDeclarators ::= h::StructDeclarator  t::StructDeclarators
{
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ env::Env -> h.unifyErrors(env) ++ t.unifyErrors(env);
  top.unifyTransform = andExpr(h.unifyTransform, t.unifyTransform);
}
aspect production nilStructDeclarator
top::StructDeclarators ::=
{
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ _ -> [];
  top.unifyTransform = mkIntConst(1);
}

aspect production structField
top::StructDeclarator ::= name::Name  ty::TypeModifierExpr  attrs::Attributes
{
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ env::Env ->
    attachNote logicalLocationFromOrigin(top) on unifyErrors(env, top.typerep, top.typerep) end;
  top.unifyTransform =
    unifyExpr(
      ableC_Expr { s1.$Name{^name} },
      ableC_Expr { s2.$Name{^name} },
      just(ableC_Expr { trail }));
}
aspect production structBitfield
top::StructDeclarator ::= name::MaybeName  ty::TypeModifierExpr  e::Expr  attrs::Attributes
{
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ env::Env ->
    attachNote logicalLocationFromOrigin(top) on unifyErrors(env, top.typerep, top.typerep) end;
  top.unifyTransform =
    case name of
    | justName(n) ->
      unifyExpr(
        ableC_Expr { s1.$Name{^n} },
        ableC_Expr { s2.$Name{^n} },
        just(ableC_Expr { trail }))
    | nothingName() -> mkIntConst(1) -- Ignore anonymous padding bits
    end;
}
aspect production warnStructField
top::StructDeclarator ::= msg::[Message]
{
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ _ -> [];
  top.unifyTransform = mkIntConst(1);
}

abstract production adtUnifyExpr implements Unify
top::Expr ::= e1::Expr e2::Expr trail::Expr refId::String
{
  top.pp = pp"unifyDatatype(${e1.pp}, ${e2.pp}, ${trail.pp})";
  attachNote extensionGenerated("ableC-unification");

  local adt::Decorated ADTDecl =
    case lookupRefId(refId, top.env) of
    | adtRefIdItem(adt) :: _ -> adt
    | _ -> error("adt demanded when not an adtRefIdItem")
    end;
  
  forwards to
    injectGlobalDeclsExpr(
      foldDecl([maybeValueDecl(adt.unifyFnName, decls(adt.unifyTransform))]),
      ableC_Expr {
        $name{adt.unifyFnName}($Expr{@e1}, $Expr{@e2}, $Expr{@trail})
      });
}

attribute unifyErrors occurs on ADTDecl, ConstructorList, Constructor, Parameters, ParameterDecl;
attribute unifyFnName occurs on ADTDecl;
attribute unifyTransform<Decls> occurs on ADTDecl;

aspect production adtDecl
top::ADTDecl ::= attrs::Attributes n::Name cs::ConstructorList
{
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors =
    \ env::Env ->
      if null(lookupValue(top.unifyFnName, env))
      then
        case attachNote logicalLocationFromOrigin(top) on cs.unifyErrors(addEnv([valueDef(top.unifyFnName, errorValueItem())], env)) end of
        | [] -> []
        | m -> [nested(getParsedOriginLocationOrFallback(ambientOrigin()), s"In unification of datatype ${top.adtGivenName}", m)]
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
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ env::Env -> c.unifyErrors(env) ++ cl.unifyErrors(env);
  top.unifyTransform = consExprClause(c.unifyTransform, cl.unifyTransform);
}

aspect production nilConstructor
top::ConstructorList ::=
{
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ _ -> [];
  top.unifyTransform = failureExprClause();
}

attribute unifyTransform<ExprClause> occurs on Constructor;

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  top.unifyErrors = ps.unifyErrors;
  top.unifyTransform =
    exprClause(
      consPattern(
        constructorPattern(^n, ps.unifyPatterns1),
        consPattern(
          constructorPattern(^n, ps.unifyPatterns2),
          nilPattern())),
      ps.unifyTransform);
}

synthesized attribute unifyPatterns1::PatternList occurs on Parameters;
synthesized attribute unifyPatterns2::PatternList occurs on Parameters;
attribute unifyTransform<Expr> occurs on Parameters;

aspect production consParameters
top::Parameters ::= h::ParameterDecl t::Parameters
{
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ env::Env -> h.unifyErrors(env) ++ t.unifyErrors(env);
  top.unifyPatterns1 = consPattern(h.unifyPattern1, t.unifyPatterns1);
  top.unifyPatterns2 = consPattern(h.unifyPattern2, t.unifyPatterns2);
  top.unifyTransform = andExpr(h.unifyTransform, t.unifyTransform);
}

aspect production nilParameters
top::Parameters ::= 
{
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ _ -> [];
  top.unifyPatterns1 = nilPattern();
  top.unifyPatterns2 = nilPattern();
  top.unifyTransform = mkIntConst(1);
}

synthesized attribute unifyPattern1::Pattern occurs on ParameterDecl;
synthesized attribute unifyPattern2::Pattern occurs on ParameterDecl;
attribute unifyTransform<Expr> occurs on ParameterDecl;

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  n::MaybeName  attrs::Attributes
{
  attachNote extensionGenerated("ableC-unification");
  top.unifyErrors = \ env::Env -> 
    attachNote logicalLocationFromOrigin(top) on unifyErrors(env, top.typerep, top.typerep) end;
  
  nondecorated local varName1::Name = name(fieldName.name ++ "1");
  nondecorated local varName2::Name = name(fieldName.name ++ "2");
  top.unifyPattern1 = patternName(varName1);
  top.unifyPattern2 = patternName(varName2);
  top.unifyTransform =
    unifyExpr(
      declRefExpr(varName1),
      declRefExpr(varName2),
      just(ableC_Expr { trail }));
}

-- Check that unification.xh is included
fun checkUnificationHeaderDef [Message] ::= env::Env =
  if !null(lookupTemplate("_var_d", env))
  then []
  else [errFromOrigin(ambientOrigin(), "Missing include of unification.xh")];
