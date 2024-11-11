grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

import silver:rewrite as s;

production freeVarExpr
top::Expr ::= ty::Type
{
  top.pp = pp"freevar<${ty.lpp}${ty.rpp}>()";
  attachNote extensionGenerated("ableC-unification");

  local localErrors::[Message] =
    (if !ty.isCompleteType(top.env)
     then [errFromOrigin(top, s"var type parameter has incomplete type ${show(80, ^ty)}")]
     else []) ++
    allocErrors(top.env) ++
    checkUnificationHeaderDef(top.env);

  nondecorated local tyName::TypeName = typeName(ty.baseTypeExpr, ty.typeModifierExpr);
  nondecorated local fwrd::Expr =
    ableC_Expr {
      proto_typedef _var_d;
      ({inst _var_d<$TypeName{tyName}> *_result =
          allocate(sizeof(inst _var_d<$TypeName{tyName}>));
        *_result = inst _Free<$TypeName{tyName}>();
        ($TypeName{
           typeName(
             ty.baseTypeExpr,
             varTypeExpr(nilQualifier(), ty.typeModifierExpr))})_result;})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

production boundVarExpr
top::Expr ::= ty::Type e::Expr
{
  top.pp = pp"boundvar<${ty.lpp}${ty.rpp}>(${e.pp})";
  attachNote extensionGenerated("ableC-unification");

  local localErrors::[Message] =
    e.errors ++
    (if !typeAssignableTo(^ty, e.typerep)
     then [errFromOrigin(top, s"Cannot construct a bound var of type ${show(80, ^ty)} from ${show(80, e.typerep)}")]
     else []) ++
    allocErrors(top.env) ++
    checkUnificationHeaderDef(top.env);

  nondecorated local tyName::TypeName = typeName(ty.baseTypeExpr, ty.typeModifierExpr);
  forward fwrd =
    ableC_Expr {
      proto_typedef _var_d;
      ({inst _var_d<$TypeName{tyName}> *_result =
          allocate(sizeof(inst _var_d<$TypeName{tyName}>));
        *_result = inst _Bound<$TypeName{tyName}>($Expr{@e});
        ($TypeName{
           typeName(
             ty.baseTypeExpr,
             varTypeExpr(nilQualifier(), ty.typeModifierExpr))})_result;})
    };

  forwards to if null(localErrors) then @fwrd else errorExpr(localErrors);
}

production newVar implements ctor:Constructor
top::Expr ::= args::Exprs
{
  top.pp = pp"new var(${ppImplode(pp", ", args.pps)})";
  forwards to ctor:bindConstructor(@args, 
    case args.typereps, args.bindRefExprs of
    | [ty], [e] -> boundVarExpr(ty, e)
    | [], [] -> errorExpr([errFromOrigin(top, "var type must be supplied to construct a free var")])
    | _, _ -> errorExpr([errFromOrigin(top, "Unexpected arguments for var construction")])
    end);
}

production newTemplateVar implements ctor:TemplateConstructor
top::Expr ::= targs::TemplateArgNames args::Exprs
{
  top.pp = pp"new var<${ppImplode(pp", ", targs.pps)}>(${ppImplode(pp", ", args.pps)})";
  targs.substEnv = s:fail();
  targs.paramNames = ["a"];
  targs.paramKinds = [nothing()];
  forwards to ctor:bindTemplateConstructor(@targs, @args, 
    case targs.argreps, args.bindRefExprs of
    | consTemplateArg(typeTemplateArg(ty), nilTemplateArg()), [e] -> boundVarExpr(^ty, e)
    | consTemplateArg(typeTemplateArg(ty), nilTemplateArg()), [] -> freeVarExpr(^ty)
    | _, _ -> errorExpr([errFromOrigin(top, "Unexpected arguments for var construction")])
    end);
}

aspect production emptyEnv
top::Env ::=
{
  globalConstructors <- [("var", newVar)];
  globalTemplateConstructors <- [("var", newTemplateVar)];
}

production deleteVar implements ctor:Destructor
top::Expr ::= e::Expr
{
  top.pp = pp"delete ${e.pp}";

  forwards to ctor:bindDestructor(@e,
    ableC_Expr { deallocate((void*)$Expr{e.bindRefExpr}) });
}

production showVar
top::Expr ::= buf::Expr e::Expr subType::Type
{
  attachNote extensionGenerated("ableC-unification");
  top.pp = pp"showVar(${buf}, ${e})";
  
  forwards to
    ableC_Expr {
      inst show_var<$directTypeExpr{^subType}>($Expr{@buf}, $Expr{@e})
    };
}

production showVarMaxLen
top::Expr ::= e::Expr subType::Type
{
  attachNote extensionGenerated("ableC-unification");
  top.pp = pp"showVarMaxLen(${e})";
  
  forwards to
    ableC_Expr {
      inst show_var_max_len<$directTypeExpr{^subType}>($Expr{@e})
    };
}
