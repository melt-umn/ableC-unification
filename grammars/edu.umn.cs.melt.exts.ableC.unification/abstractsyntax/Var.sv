grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

import edu:umn:cs:melt:ableC:abstractsyntax:overloadable;

global expectedAllocatorType::Type =
  pointerType(
    nilQualifier(),
    functionType(
      pointerType(
        nilQualifier(),
        builtinType(nilQualifier(), voidType())),
      protoFunctionType([builtinType(nilQualifier(), unsignedType(longType()))], false),
      nilQualifier()));

abstract production freeVarExpr
top::Expr ::= ty::TypeName allocator::Expr
{
  top.pp = pp"freevar<${ty.pp}>(${allocator.pp})";
  propagate env, controlStmtContext;

  local localErrors::[Message] =
    ty.errors ++ allocator.errors ++
    (if !ty.typerep.isCompleteType(addEnv(ty.defs, ty.env))
     then [errFromOrigin(top, s"var type parameter has incomplete type ${showType(ty.typerep)}")]
     else []) ++
    (if !typeAssignableTo(expectedAllocatorType, allocator.typerep)
     then [errFromOrigin(allocator, s"Allocator must have type void *(unsigned long) (got ${showType(allocator.typerep)})")]
     else []) ++
    checkUnificationHeaderTemplateDef("_var_d", top.env);
  
  local fwrd::Expr =
    ableC_Expr {
      proto_typedef _var_d;
      ({inst _var_d<$TypeName{ty}> *_result =
          $Expr{allocator}(sizeof(inst _var_d<$directTypeExpr{ty.typerep}>));
        *_result = inst _Free<$directTypeExpr{ty.typerep}>();
        ($TypeName{
           typeName(
             directTypeExpr(ty.typerep),
             varTypeExpr(nilQualifier(), baseTypeExpr()))})_result;})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production boundVarExpr
top::Expr ::= allocator::Expr e::Expr
{
  top.pp = pp"boundvar(${allocator.pp}, ${e.pp})";
  propagate env, controlStmtContext;
  
  local localErrors::[Message] =
    allocator.errors ++ e.errors ++
    (if !typeAssignableTo(expectedAllocatorType, allocator.typerep)
     then [errFromOrigin(allocator, s"Allocator must have type void *(unsigned long) (got ${showType(allocator.typerep)})")]
     else []) ++
    checkUnificationHeaderTemplateDef("_var_d", top.env);
  
  local type::Type = e.typerep.defaultFunctionArrayLvalueConversion.canonicalType;
  local fwrd::Expr =
    ableC_Expr {
      proto_typedef _var_d;
      ({inst _var_d<$directTypeExpr{type}> *_result =
          $Expr{allocator}(sizeof(inst _var_d<$directTypeExpr{type}>));
        *_result = inst _Bound<$directTypeExpr{type}>($Expr{e}); // TODO: redecoration here!
        ($TypeName{
           typeName(
             directTypeExpr(type),
             varTypeExpr(nilQualifier(), baseTypeExpr()))})_result;})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}
