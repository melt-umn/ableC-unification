grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

import edu:umn:cs:melt:ableC:abstractsyntax:overloadable;

abstract production varTypeExpr
top::TypeModifierExpr ::= q::Qualifiers sub::TypeModifierExpr
{
  top.lpp = pp"${sub.lpp} ${terminate(space(), q.pps)}";
  top.rpp = sub.rpp;
  top.isFunctionArrayTypeExpr = false;
  attachNote extensionGenerated("ableC-unification");
  propagate baseType, typeModifierIn, controlStmtContext;
  
  top.inferredArgs := sub.inferredArgs;
  top.argumentBaseType = sub.argumentBaseType;
  sub.argumentType =
    case top.argumentType of
    | extType(_, varType(t)) -> t
    -- Be liberal here in case inferring where any unifiable type is permitted,
    -- errors will be caught later.
    | t -> t
    end;
  
  sub.env = globalEnv(top.env);
  
  local localErrors::[Message] =
    sub.errors ++
    checkUnificationHeaderTemplateDef("_var_d", top.env);
  
  local globalDecls::Decls =
    foldDecl(
      sub.decls ++
      [templateTypeExprInstDecl(
        q, name("_var_d"),
        foldTemplateArg([typeTemplateArg(sub.typerep)]))]);
  
  -- Non-interfering overrides for better performance
  top.decls := [injectGlobalDeclsDecl(globalDecls)];
  top.errors := localErrors;
  top.typerep =
    case sub.typerep of
    | errorType() -> errorType()
    | _ -> extType(q, varType(sub.typerep))
    end;
  
  forwards to
    modifiedTypeExpr(
      if !null(localErrors) || case sub.typerep of errorType() -> true | _ -> false end
      then errorTypeExpr(localErrors)
      else injectGlobalDeclsTypeExpr(globalDecls, extTypeExpr(q, varType(sub.typerep))));
}

synthesized attribute unifyErrors::([Message] ::= Decorated Env) occurs on Type, ExtType;
synthesized attribute unifyProd::(Expr ::= Expr Expr Expr) occurs on Type, ExtType;

aspect default production
top::Type ::=
{
  -- TODO: Types should both be equality types
  top.unifyErrors =
    \ env::Decorated Env ->
      case top.otherType of
      | extType(_, varType(sub)) ->
        if compatibleTypes(top, sub.defaultFunctionArrayLvalueConversion, false, false)
        then decorate top with {otherType = sub;}.unifyErrors(env)
        else [errFromOrigin(ambientOrigin(), s"Unification value and variable types must match (got ${showType(top)}, ${showType(sub)})")]
      | t ->
        if compatibleTypes(top, t, false, false)
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification value types must match (got ${showType(top)}, ${showType(t)})")]
      end;
  top.unifyProd =
    case top.otherType of
    | extType(_, varType(_)) -> valVarUnifyExpr
    | errorType() -> \ _ _ _ -> errorExpr([])
    | _ -> defaultUnifyExpr
    end;
}

aspect production errorType
top::Type ::= 
{
  top.unifyErrors = \ _ -> [];
  top.unifyProd = \ _ _ _ -> errorExpr([]);
}

aspect production extType
top::Type ::= q::Qualifiers  sub::ExtType
{
  top.unifyErrors = sub.unifyErrors;
  top.unifyProd = sub.unifyProd;
}

aspect default production
top::ExtType ::=
{
  top.unifyErrors = \ _ ->
    [errFromOrigin(ambientOrigin, s"Unification is not defined for types ${showType(extType(top.givenQualifiers, top))}, ${showType(top.otherType)}")];
  top.unifyProd = \ _ _ _ -> errorExpr([]);
}

abstract production varType
top::ExtType ::= sub::Type
{
  propagate canonicalType;
  top.lpp = sub.lpp;
  top.rpp = pp" ? ${terminate(space(), top.givenQualifiers.pps)}${sub.rpp}";
  top.pp = error("TODO");
  top.host =
    pointerType(
      top.givenQualifiers,
      extType(
        nilQualifier(),
        adtExtType(
          "_var_d",
          templateMangledName("_var_d", foldTemplateArg([typeTemplateArg(sub)])),
          templateMangledRefId("_var_d", foldTemplateArg([typeTemplateArg(sub)])))).host);
  top.baseTypeExpr = sub.baseTypeExpr;
  top.typeModifierExpr = varTypeExpr(top.givenQualifiers, sub.typeModifierExpr);
  top.mangledName = s"var_${sub.mangledName}_";
  top.isEqualTo =
    \ other::ExtType ->
      case other of
      | varType(otherSub) -> compatibleTypes(sub, otherSub, false, false)
      | _ -> false
      end;
  
  top.showErrors =
    \ env::Decorated Env ->
      showErrors(env, sub) ++
      case sub.maybeRefId of
      | just(refId) when lookupRefId(refId, globalEnv(env)) matches [] ->
        [errFromOrigin(ambientOrigin(), s"${showType(sub)} does not have a (global) definition.")]
      | _ -> []
      end ++
      checkUnificationHeaderTemplateDef("show_var", env);
  top.strErrors =
    \ env::Decorated Env ->
      sub.strErrors(env) ++
      checkUnificationHeaderTemplateDef("str_var", env);
  top.showProd =
    \ e::Expr -> ableC_Expr { inst show_var<$directTypeExpr{sub}>($Expr{e}) };
  top.strProd =
    \ e::Expr -> ableC_Expr { inst str_var<$directTypeExpr{sub}>($Expr{e}) };
  
  local topType::Type = extType(top.givenQualifiers, top);
  top.unifyErrors =
    \ env::Decorated Env ->
      case top.otherType of
      | extType(_, varType(otherSub)) ->
        if compatibleTypes(sub.defaultFunctionArrayLvalueConversion, otherSub.defaultFunctionArrayLvalueConversion, false, true)
        then decorate sub.defaultFunctionArrayLvalueConversion with {otherType = otherSub.defaultFunctionArrayLvalueConversion;}.unifyErrors(env)
        else [errFromOrigin(ambientOrigin(), s"Unification variable types must match (got ${showType(sub)}, ${showType(otherSub)})")]
      | t ->
        if compatibleTypes(sub.defaultFunctionArrayLvalueConversion, t, false, true)
        then decorate sub.defaultFunctionArrayLvalueConversion with {otherType = t;}.unifyErrors(env)
        else [errFromOrigin(ambientOrigin(), s"Unification variable and value types must match (got ${showType(sub)}, ${showType(t)})")]
      end;
  top.unifyProd =
    case top.otherType of
    | extType(_, varType(_)) -> varVarUnifyExpr
    | errorType() -> \ _ _ _ -> errorExpr([])
    | _ -> varValUnifyExpr
    end;
}

aspect production stringType
top::ExtType ::=
{
  top.unifyErrors =
    \ env::Decorated Env ->
      case top.otherType of
      | extType(_, varType(sub)) ->
        if compatibleTypes(extType(nilQualifier(), stringType()), sub.defaultFunctionArrayLvalueConversion, false, true)
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification value and variable types must match (got string, ${showType(sub)})")]
      | t ->
        if compatibleTypes(extType(nilQualifier(), stringType()), t, false, true)
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification value types must match (got string, ${showType(t)})")]
      end;
  top.unifyProd =
    case top.otherType of
    | extType(_, varType(_)) -> valVarUnifyExpr
    | errorType() -> \ _ _ _ -> errorExpr([])
    | _ -> defaultUnifyExpr
    end;
}

aspect production enumExtType
top::ExtType ::= ref::Decorated EnumDecl
{
  local topType::Type = extType(top.givenQualifiers, top);
  top.unifyErrors =
    \ env::Decorated Env ->
      case top.otherType of
      | extType(_, varType(sub)) ->
        if compatibleTypes(topType, sub.defaultFunctionArrayLvalueConversion, false, true)
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification value and variable types must match (got ${showType(topType)}, ${showType(sub)})")]
      | t ->
        if compatibleTypes(topType, t, false, false)
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification value types must match (got ${showType(topType)}, ${showType(t)})")]
      end;
  top.unifyProd =
    case top.otherType of
    | extType(_, varType(_)) -> valVarUnifyExpr
    | errorType() -> \ _ _ _ -> errorExpr([])
    | _ -> defaultUnifyExpr
    end;
}

aspect production refIdExtType
top::ExtType ::= kwd::StructOrEnumOrUnion  _  refId::String
{
  local topType::Type = extType(top.givenQualifiers, top);
  top.unifyErrors =
    \ env::Decorated Env ->
      case kwd, top.otherType of
      | structSEU(), extType(_, refIdExtType(structSEU(), otherName, otherRefId)) ->
        if refId == otherRefId
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification struct types must match (got struct ${tagName}, struct ${fromMaybe("<anon>", otherName)})")]
      | structSEU(), extType(_, varType(extType(_, refIdExtType(structSEU(), otherName, otherRefId)))) ->
        if refId == otherRefId
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification value and variable struct types must match (got struct ${tagName}, datatype ${fromMaybe("<anon>", otherName)})")]
      | structSEU(), errorType() -> []
      | structSEU(), t -> [errFromOrigin(ambientOrigin(), s"Unification is not defined for struct ${tagName} and non-struct ${showType(t)}")]
      | unionSEU(), _ -> [errFromOrigin(ambientOrigin(), s"Unification is not defined for unions")]
      | enumSEU(), _ -> error("Unexpected enum refIdExtType")
      end ++
      case lookupRefId(refId, globalEnv(env)) of
      | structRefIdItem(struct) :: _ -> struct.unifyErrors(env)
      | _ -> [errFromOrigin(ambientOrigin(), s"struct ${tagName} does not have a (global) definition.")]
      end;
  top.unifyProd =
    case top.otherType of
    | extType(_, refIdExtType(_, _, _)) -> structUnifyExpr
    | extType(_, varType(_)) -> valVarUnifyExpr
    | _ -> \ _ _ _ -> errorExpr([])
    end;
}

aspect production adtExtType
top::ExtType ::= adtName::String adtDeclName::String refId::String
{
  local topType::Type = extType(top.givenQualifiers, top);
  top.unifyErrors =
    \ env::Decorated Env ->
      case top.otherType of
      | extType(_, adtExtType(otherAdtName, _, otherRefId)) ->
        if refId == otherRefId
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification datatypes must match (got datatype ${adtName}, datatype ${otherAdtName})")]
      | extType(_, varType(extType(_, adtExtType(otherAdtName, _, otherRefId)))) ->
        if refId == otherRefId
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification value and variable datatypes must match (got datatype ${adtName}, datatype ${otherAdtName})")]
      | errorType() -> []
      | t -> [errFromOrigin(ambientOrigin(), s"Unification is not defined for datatype ${adtName} and non-datatype ${showType(t)}")]
      end ++
      case lookupRefId(refId, globalEnv(env)) of
      | adtRefIdItem(adt) :: _ -> adt.unifyErrors(env)
      | _ -> [errFromOrigin(ambientOrigin(), s"datatype ${adtName} does not have a (global) definition.")]
      end;
  top.unifyProd =
    case top.otherType of
    | extType(_, adtExtType(_, _, _)) -> adtUnifyExpr
    | extType(_, varType(_)) -> valVarUnifyExpr
    | _ -> \ _ _ _ -> errorExpr([])
    end;
}

-- Find the sub-type of a var type
function varSubType
Type ::= t::Type
{
  return
    case t of
    | extType(_, varType(sub)) -> sub
    | _ -> errorType()
    end;
}
