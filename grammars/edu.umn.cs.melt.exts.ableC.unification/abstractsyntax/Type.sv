grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

abstract production varTypeExpr
top::TypeModifierExpr ::= q::Qualifiers sub::TypeModifierExpr
{
  top.lpp = pp"${sub.lpp} ${terminate(space(), q.pps)}";
  top.rpp = sub.rpp;
  top.isFunctionArrayTypeExpr = false;
  attachNote extensionGenerated("ableC-unification");
  
  top.inferredArgs := sub.inferredArgs;
  top.argumentBaseType = sub.argumentBaseType;
  sub.argumentType =
    case top.argumentType of
    | extType(_, varType(t)) -> ^t
    -- Be liberal here in case inferring where any unifiable type is permitted,
    -- errors will be caught later.
    | t -> t
    end;
  
  local localErrors::[Message] =
    sub.errors ++
    checkUnificationHeaderDef(top.env);
  
  local globalDecls::Decls =
    consDecl(
      typePreDecls(typeName(directTypeExpr(top.baseType), @sub)),
      consDecl(
        templateTypeExprInstDecl(
          ^q, name("_var_d"),
          foldTemplateArg([typeTemplateArg(sub.typerep)])),
        nilDecl()));

  forward fwrd = modifiedTypeExpr(
    injectGlobalDeclsTypeExpr(@globalDecls, extTypeExpr(@q, varType(sub.typerep))));

  forwards to
    if !null(localErrors) || case sub.typerep of errorType() -> true | _ -> false end
    then modifiedTypeExpr(errorTypeExpr(localErrors))
    else @fwrd;
}

synthesized attribute unifyErrors::([Message] ::= Env) occurs on Type, ExtType;
synthesized attribute unifyProd::Unify occurs on Type, ExtType;

aspect default production
top::Type ::=
{
  -- TODO: Types should both be equality types
  top.unifyErrors =
    \ env::Env ->
      case top.otherType of
      | extType(_, varType(sub)) ->
        if compatibleTypes(^top, sub.defaultFunctionArrayLvalueConversion, false, false)
        then decorate ^top with {otherType = ^sub;}.unifyErrors(env)
        else [errFromOrigin(ambientOrigin(), s"Unification value and variable types must match (got ${show(80, ^top)}, ${show(80, ^sub)})")]
      | t ->
        if compatibleTypes(^top, t, false, false)
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification value types must match (got ${show(80, ^top)}, ${show(80, t)})")]
      end;
  top.unifyProd =
    case top.otherType of
    | extType(_, varType(otherSub)) -> valVarUnifyExpr(top.mergeQualifiers(^otherSub))
    | _ -> defaultUnifyExpr
    end;
}

aspect production errorType
top::Type ::= 
{
  top.unifyErrors = \ _ -> [];
  top.unifyProd = defaultUnifyExpr;
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
    [errFromOrigin(ambientOrigin, s"Unification is not defined for types ${show(80, extType(top.givenQualifiers, ^top))}, ${show(80, top.otherType)}")];
  top.unifyProd = defaultUnifyExpr;
}

abstract production varType
top::ExtType ::= sub::Type
{
  propagate canonicalType;
  top.lpp = sub.lpp;
  top.rpp = pp" ? ${terminate(space(), top.givenQualifiers.pps)}${sub.rpp}";
  top.pp = error("TODO");
  local targs::TemplateArgs = foldTemplateArg([typeTemplateArg(^sub)]);
  top.host =
    pointerType(
      top.givenQualifiers,
      extType(
        nilQualifier(),
        adtExtType(
          "_var_d",
          targs.templateMangledName("_var_d"),
          targs.templateMangledRefId("_var_d"))).host);
  top.baseTypeExpr = sub.baseTypeExpr;
  top.typeModifierExpr = varTypeExpr(top.givenQualifiers, sub.typeModifierExpr);
  top.mangledName = s"var_${sub.mangledName}_";
  top.isEqualTo =
    \ other::ExtType ->
      case other of
      | varType(otherSub) -> compatibleTypes(^sub, ^otherSub, false, false)
      | _ -> false
      end;

  top.ctor:deleteProd = just(deleteVar);
  
  top.showErrors :=
    \ env::Env ->
      showErrors(env, ^sub) ++
      case sub.maybeRefId of
      | just(refId) when lookupRefId(refId, globalEnv(env)) matches [] ->
        [errFromOrigin(ambientOrigin(), s"${show(80, ^sub)} does not have a (global) definition.")]
      | _ -> []
      end ++
      checkUnificationHeaderDef(env);
  top.showMaxLenProd = showVarMaxLen(_, ^sub);
  top.showProd = showVar(_, _, ^sub);
  
  nondecorated local topType::Type = extType(top.givenQualifiers, ^top);
  top.unifyErrors =
    \ env::Env ->
      case top.otherType of
      | extType(_, varType(otherSub)) ->
        if compatibleTypes(sub.defaultFunctionArrayLvalueConversion, otherSub.defaultFunctionArrayLvalueConversion, false, true)
        then decorate sub.defaultFunctionArrayLvalueConversion with {otherType = otherSub.defaultFunctionArrayLvalueConversion;}.unifyErrors(env)
        else [errFromOrigin(ambientOrigin(), s"Unification variable types must match (got ${show(80, ^sub)}, ${show(80, ^otherSub)})")]
      | t ->
        if compatibleTypes(sub.defaultFunctionArrayLvalueConversion, t, false, true)
        then decorate sub.defaultFunctionArrayLvalueConversion with {otherType = t;}.unifyErrors(env)
        else [errFromOrigin(ambientOrigin(), s"Unification variable and value types must match (got ${show(80, ^sub)}, ${show(80, t)})")]
      end;
  top.unifyProd =
    case top.otherType of
    | extType(_, varType(otherSub)) -> varVarUnifyExpr(sub.mergeQualifiers(^otherSub))
    | errorType() -> defaultUnifyExpr
    | _ -> varValUnifyExpr(sub.mergeQualifiers(top.otherType))
    end;
}

aspect production stringType
top::ExtType ::=
{
  top.unifyErrors =
    \ env::Env ->
      case top.otherType of
      | extType(_, varType(sub)) ->
        if compatibleTypes(extType(nilQualifier(), stringType()), sub.defaultFunctionArrayLvalueConversion, false, true)
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification value and variable types must match (got string, ${show(80, ^sub)})")]
      | t ->
        if compatibleTypes(extType(nilQualifier(), stringType()), t, false, true)
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification value types must match (got string, ${show(80, t)})")]
      end;
  top.unifyProd =
    case top.otherType of
    | extType(_, varType(otherSub)) -> valVarUnifyExpr(^otherSub)
    | _ -> defaultUnifyExpr
    end;
}

aspect production enumExtType
top::ExtType ::= ref::Decorated EnumDecl
{
  nondecorated local topType::Type = extType(top.givenQualifiers, ^top);
  top.unifyErrors =
    \ env::Env ->
      case top.otherType of
      | extType(_, varType(sub)) ->
        if compatibleTypes(topType, sub.defaultFunctionArrayLvalueConversion, false, true)
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification value and variable types must match (got ${show(80, topType)}, ${show(80, ^sub)})")]
      | t ->
        if compatibleTypes(topType, t, false, false)
        then []
        else [errFromOrigin(ambientOrigin(), s"Unification value types must match (got ${show(80, topType)}, ${show(80, t)})")]
      end;
  top.unifyProd =
    case top.otherType of
    | extType(_, varType(otherSub)) -> valVarUnifyExpr(^otherSub)
    | _ -> defaultUnifyExpr
    end;
}

aspect production refIdExtType
top::ExtType ::= kwd::StructOrEnumOrUnion  _  refId::String
{
  nondecorated local topType::Type = extType(top.givenQualifiers, ^top);
  top.unifyErrors =
    \ env::Env ->
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
      | structSEU(), t -> [errFromOrigin(ambientOrigin(), s"Unification is not defined for struct ${tagName} and non-struct ${show(80, t)}")]
      | unionSEU(), _ -> [errFromOrigin(ambientOrigin(), s"Unification is not defined for unions")]
      | enumSEU(), _ -> error("Unexpected enum refIdExtType")
      end ++
      case lookupRefId(refId, globalEnv(env)) of
      | structRefIdItem(struct) :: _ -> struct.unifyErrors(env)
      | _ -> [errFromOrigin(ambientOrigin(), s"struct ${tagName} does not have a (global) definition.")]
      end;
  top.unifyProd =
    case top.otherType of
    | extType(_, refIdExtType(_, _, _)) -> structUnifyExpr(refId)
    | extType(_, varType(otherSub)) -> valVarUnifyExpr(^otherSub)
    | _ -> defaultUnifyExpr
    end;
}

aspect production adtExtType
top::ExtType ::= adtName::String adtDeclName::String refId::String
{
  nondecorated local topType::Type = extType(top.givenQualifiers, ^top);
  top.unifyErrors =
    \ env::Env ->
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
      | t -> [errFromOrigin(ambientOrigin(), s"Unification is not defined for datatype ${adtName} and non-datatype ${show(80, t)}")]
      end ++
      case lookupRefId(refId, globalEnv(env)) of
      | adtRefIdItem(adt) :: _ -> adt.unifyErrors(env)
      | _ -> [errFromOrigin(ambientOrigin(), s"datatype ${adtName} does not have a (global) definition.")]
      end;
  top.unifyProd =
    case top.otherType of
    | extType(_, adtExtType(_, _, _)) -> adtUnifyExpr(refId)
    | extType(_, varType(otherSub)) -> valVarUnifyExpr(^otherSub)
    | _ -> defaultUnifyExpr
    end;
}

-- Find the sub-type of a var type
function varSubType
Type ::= t::Type
{
  return
    case t of
    | extType(_, varType(sub)) -> ^sub
    | _ -> errorType()
    end;
}
