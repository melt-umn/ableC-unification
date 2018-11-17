grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

import edu:umn:cs:melt:ableC:abstractsyntax:overloadable;

abstract production freshVarExpr
top::Expr ::= ty::TypeName allocator::Expr
{
  propagate substituted;
  top.pp = pp"freshvar<${ty.pp}>(${allocator.pp})";
  
  local expectedAllocatorType::Type =
    functionType(
      pointerType(
        nilQualifier(),
        builtinType(nilQualifier(), voidType())),
      protoFunctionType([builtinType(nilQualifier(), unsignedType(longType()))], false),
      nilQualifier());
  
  local localErrors::[Message] =
    ty.errors ++ allocator.errors ++
    (if !ty.typerep.isCompleteType(top.env)
     then [err(top.location, s"var type parameter has incomplete type ${showType(ty.typerep)}")]
     else []) ++
    (if !compatibleTypes(expectedAllocatorType, allocator.typerep, true, false)
     then [err(allocator.location, s"Allocator must have type void *(unsigned long) (got ${showType(allocator.typerep)})")]
     else []) ++
    checkUnificationHeaderTemplateDef("_var_d", top.location, top.env);
  
  local fwrd::Expr =
    ableC_Expr {
      proto_typedef _var_d;
      ({inst _var_d<$TypeName{ty}> *_result =
          $Expr{allocator}(sizeof(inst _var_d<$directTypeExpr{ty.typerep}>));
        *_result = inst _Free<$directTypeExpr{ty.typerep}>();
        ($TypeName{
           typeName(
             directTypeExpr(ty.typerep),
             varTypeExpr(nilQualifier(), baseTypeExpr(), builtin))})_result;})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production showVar
top::Expr ::= e::Expr
{
  propagate substituted;
  top.pp = pp"show(${e.pp})";
  
  local subType::Type = varSubType(e.typerep);
  local localErrors::[Message] =
    (if !subType.isCompleteType(top.env)
     then [err(top.location, s"var type parameter has incomplete type ${showType(subType)}")]
     else []) ++
    checkUnificationHeaderTemplateDef("show_var", top.location, top.env);
  
  local fwrd::Expr =
    ableC_Expr { inst show_var<$directTypeExpr{subType}>($Expr{e}) };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}
