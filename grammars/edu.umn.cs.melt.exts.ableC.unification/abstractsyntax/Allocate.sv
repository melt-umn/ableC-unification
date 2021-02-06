grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

abstract production varReferenceDecl
top::Decl ::= id::Name  allocator::Name pfx::Maybe<Name>
{
  top.pp = pp"var_reference datatype ${id.pp} with ${allocator.pp};";
  
  local expectedAllocatorType::Type =
    functionType(
      pointerType(
        nilQualifier(),
        builtinType(nilQualifier(), voidType())),
      protoFunctionType([builtinType(nilQualifier(), unsignedType(longType()))], false),
      nilQualifier());
  local adtLookupErrors::[Message] =
    case lookupTag(id.name, top.env) of
    | adtRefIdTagItem(refId) :: _ ->
      case lookupRefId(refId, top.env) of
      | adtRefIdItem(_) :: _ -> []
      | _ -> [err(id.location, "datatype " ++ id.name ++ " does not have a definition")]
      end
    | _ -> [err(id.location, "Tag " ++ id.name ++ " is not a datatype")]
    end;
  local localErrors::[Message] =
    adtLookupErrors ++ allocator.valueLookupCheck ++
    (if !compatibleTypes(expectedAllocatorType, allocator.valueItem.typerep, true, false)
     then [err(allocator.location, s"Allocator must have type void *(unsigned long) (got ${showType(allocator.valueItem.typerep)})")]
     else []);
  
  local adtLookup::Decorated ADTDecl =
    case id.tagItem of
    | adtRefIdTagItem(refId) ->
      case lookupRefId(refId, top.env) of
      | adtRefIdItem(d) :: _ -> d
      end
    end;
  -- Re-decorate the found ADT decl, also supplying the allocator name
  local d::ADTDecl = new(adtLookup);
  d.env = top.env; -- TODO: Not exactly correct, but the decl needs to see the tag to avoid re-generating the refId
  d.returnType = adtLookup.returnType;
  d.breakValid = adtLookup.breakValid;
  d.continueValid = adtLookup.continueValid;
  d.isTopLevel = adtLookup.isTopLevel;
  d.givenRefId = adtLookup.givenRefId;
  d.adtGivenName = adtLookup.adtGivenName;
  d.allocatorName = allocator;
  d.allocatePfx =
    case pfx of
    | just(pfx) -> pfx.name
    | nothing() -> allocator.name ++ "_"
    end;
  
  forwards to
    if !null(adtLookupErrors)
    then warnDecl(localErrors)
    else if !null(localErrors)
    then decls(foldDecl([warnDecl(localErrors), defsDecl(d.varReferenceErrorDefs)]))
    else defsDecl(d.varReferenceDefs);
}

abstract production templateVarReferenceDecl
top::Decl ::= id::Name  allocator::Name pfx::Maybe<Name>
{
  top.pp = pp"template var_reference datatype ${id.pp} with ${allocator.pp};";
  
  local expectedAllocatorType::Type =
    functionType(
      pointerType(
        nilQualifier(),
        builtinType(nilQualifier(), voidType())),
      protoFunctionType([builtinType(nilQualifier(), unsignedType(longType()))], false),
      nilQualifier());
  local adtLookupErrors::[Message] =
    case lookupTemplate(id.name, top.env) of
    | adtTemplateItem(params, adt) :: _ -> []
    | _ -> [err(id.location, id.name ++ " is not a template datatype")]
    end;
  local localErrors::[Message] =
    adtLookupErrors ++ allocator.valueLookupCheck ++
    (if !compatibleTypes(expectedAllocatorType, allocator.valueItem.typerep, true, false)
     then [err(allocator.location, s"Allocator must have type void *(unsigned long) (got ${showType(allocator.valueItem.typerep)})")]
     else []);
  
  local adtLookup::Decorated ADTDecl =
    case lookupTemplate(id.name, top.env) of
    | adtTemplateItem(params, adt) :: _ -> adt
    end;
  -- Re-decorate the found ADT decl, also supplying the allocator name
  local d::ADTDecl = new(adtLookup);
  d.env = adtLookup.env;
  d.returnType = adtLookup.returnType;
  d.breakValid = adtLookup.breakValid;
  d.continueValid = adtLookup.continueValid;
  d.adtGivenName = adtLookup.adtGivenName;
  d.templateParameters =
    case lookupTemplate(id.name, top.env) of
    | adtTemplateItem(params, adt) :: _ -> params
    end;
  d.allocatorName = allocator;
  d.allocatePfx =
    case pfx of
    | just(pfx) -> pfx.name
    | nothing() -> allocator.name ++ "_"
    end;
  
  forwards to
    if !null(adtLookupErrors)
    then warnDecl(localErrors)
    else if !null(localErrors)
    then decls(foldDecl([warnDecl(localErrors), defsDecl(d.templateVarReferenceErrorDefs)]))
    else defsDecl(d.templateVarReferenceDefs);
}


synthesized attribute varReferenceDefs::[Def] occurs on ADTDecl, ConstructorList, Constructor;
synthesized attribute varReferenceErrorDefs::[Def] occurs on ADTDecl, ConstructorList, Constructor;
synthesized attribute templateVarReferenceDefs::[Def] occurs on ADTDecl, ConstructorList, Constructor;
synthesized attribute templateVarReferenceErrorDefs::[Def] occurs on ADTDecl, ConstructorList, Constructor;

aspect production adtDecl
top::ADTDecl ::= attrs::Attributes n::Name cs::ConstructorList
{
  top.varReferenceDefs = cs.varReferenceDefs;
  top.varReferenceErrorDefs = cs.varReferenceErrorDefs;
  top.templateVarReferenceDefs = cs.templateVarReferenceDefs;
  top.templateVarReferenceErrorDefs = cs.templateVarReferenceErrorDefs;
}

aspect production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  top.varReferenceDefs = c.varReferenceDefs ++ cl.varReferenceDefs;
  top.varReferenceErrorDefs = c.varReferenceErrorDefs ++ cl.varReferenceErrorDefs;
  top.templateVarReferenceDefs = c.templateVarReferenceDefs ++ cl.templateVarReferenceDefs;
  top.templateVarReferenceErrorDefs = c.templateVarReferenceErrorDefs ++ cl.templateVarReferenceErrorDefs;
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.varReferenceDefs = [];
  top.varReferenceErrorDefs = [];
  top.templateVarReferenceDefs = [];
  top.templateVarReferenceErrorDefs = [];
}

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  top.varReferenceDefs =
    [valueDef(
       allocateConstructorName,
       varReferenceConstructorValueItem(
         name(top.adtGivenName, location=builtin),
         top.allocatorName, n, ps.typereps))];
  top.varReferenceErrorDefs = [valueDef(allocateConstructorName, errorValueItem())];
  top.templateVarReferenceDefs =
    [templateDef(
       allocateConstructorName,
       constructorTemplateItem(
         n.location,
         top.templateParameters.names, top.templateParameters.kinds, ps, -- TODO: location should be allocate decl location
         templateVarReferenceConstructorInstDecl(
           name(top.adtGivenName, location=builtin),
           top.allocatorName, n, _, top.templateParameters.asTemplateArgNames, ps)))];
  top.templateVarReferenceErrorDefs = [templateDef(allocateConstructorName, errorTemplateItem())];
}

abstract production varReferenceConstructorValueItem
top::ValueItem ::= adtName::Name allocatorName::Name constructorName::Name paramTypes::[Type]
{
  top.pp = pp"varReferenceConstructorValueItem(${adtName.pp}, ${allocatorName.pp}, ${constructorName.pp})";
  top.typerep = errorType();
  top.sourceLocation = allocatorName.location;
  top.directRefHandler =
    \ n::Name l::Location ->
      errorExpr([err(l, s"Var reference constructor ${n.name} cannot be referenced, only called directly")], location=builtin);
  top.directCallHandler =
    varReferenceConstructorCallExpr(adtName, allocatorName, constructorName, paramTypes, _, _, location=_);
}

abstract production varReferenceConstructorCallExpr
top::Expr ::= adtName::Name allocatorName::Name constructorName::Name paramTypes::[Type] n::Name args::Exprs
{
  top.pp = parens(ppConcat([n.pp, parens(ppImplode(cat(comma(), space()), args.pps))]));
  local localErrors::[Message] = args.errors ++ args.argumentErrors;
  
  args.expectedTypes = paramTypes;
  args.argumentPosition = 1;
  args.callExpr = decorate declRefExpr(n, location=n.location) with {env = top.env; 
    returnType = top.returnType; breakValid=top.breakValid; continueValid=top.continueValid;};
  args.callVariadic = false;
  
  local adtTypeExpr::BaseTypeExpr = adtTagReferenceTypeExpr(nilQualifier(), adtName);
  local resultTypeExpr::BaseTypeExpr =
    typeModifierTypeExpr(adtTypeExpr, varTypeExpr(nilQualifier(), baseTypeExpr(), builtin));
  local resultName::String = "result_" ++ toString(genInt());
  local fwrd::Expr =
    ableC_Expr {
      proto_typedef _var_d;
      ({$BaseTypeExpr{resultTypeExpr} $name{resultName} =
          ($BaseTypeExpr{resultTypeExpr})$Name{allocatorName}(
            sizeof(inst _var_d<$BaseTypeExpr{adtTypeExpr}>));
        *(inst _var_d<$BaseTypeExpr{adtTypeExpr}> *)$name{resultName} =
          inst _Bound<$BaseTypeExpr{adtTypeExpr}>($Name{constructorName}($Exprs{args}));
        $name{resultName};})
    };
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production templateVarReferenceConstructorInstDecl
top::Decl ::= adtName::Name allocatorName::Name constructorName::Name n::Name ts::TemplateArgNames ps::Parameters
{
  top.pp = pp"templateVarReferenceConstructorInstDecl ${n.pp};";
  
  ps.position = 0;
  forwards to
    defsDecl([
      valueDef(
        n.name,
        templateVarReferenceConstructorInstValueItem(
          adtName, allocatorName, constructorName, ts, ps.typereps))]);
}

abstract production templateVarReferenceConstructorInstValueItem
top::ValueItem ::= adtName::Name allocatorName::Name constructorName::Name ts::TemplateArgNames paramTypes::[Type]
{
  top.pp = pp"templateVarReferenceConstructorInstValueItem(${adtName.pp}, ${allocatorName.pp}, ${constructorName.pp})";
  top.typerep = errorType();
  top.sourceLocation = allocatorName.location;
  top.directRefHandler =
    \ n::Name l::Location ->
      errorExpr([err(l, s"Var reference constructor ${allocatorName.name}_${adtName.name}<${show(80, ppImplode(pp", ", ts.pps))}> cannot be referenced, only called directly")], location=builtin);
  top.directCallHandler =
    templateVarReferenceConstructorInstCallExpr(adtName, allocatorName, constructorName, ts, paramTypes, _, _, location=_);
}

abstract production templateVarReferenceConstructorInstCallExpr
top::Expr ::= adtName::Name allocatorName::Name constructorName::Name ts::TemplateArgNames paramTypes::[Type] n::Name args::Exprs
{
  top.pp = parens(ppConcat([n.pp, parens(ppImplode(cat(comma(), space()), args.pps))]));
  local localErrors::[Message] = args.errors ++ args.argumentErrors;
  
  args.expectedTypes = paramTypes;
  args.argumentPosition = 1;
  args.callExpr = decorate declRefExpr(n, location=n.location) with {env = top.env; 
    returnType = top.returnType; breakValid=top.breakValid; continueValid=top.continueValid;};
  args.callVariadic = false;
  
  local resultTypeExpr::BaseTypeExpr =
    typeModifierTypeExpr(
      templateTypedefTypeExpr(nilQualifier(), adtName, ts),
      varTypeExpr(nilQualifier(), baseTypeExpr(), builtin));
  local resultName::String = "result_" ++ toString(genInt());
  local fwrd::Expr =
    ableC_Expr {
      proto_typedef _var_d;
      ({$BaseTypeExpr{resultTypeExpr} $name{resultName} =
          ($BaseTypeExpr{resultTypeExpr})$Name{allocatorName}(
            sizeof(inst _var_d<inst $TName{adtName}<$TemplateArgNames{ts}>>));
        *(inst _var_d<inst $TName{adtName}<$TemplateArgNames{ts}>> *)$name{resultName} =
          inst _Bound<inst $TName{adtName}<$TemplateArgNames{ts}>>(
            inst $Name{constructorName}<$TemplateArgNames{ts}>($Exprs{args}));
        $name{resultName};})
    };
  forwards to mkErrorCheck(localErrors, fwrd);
}
