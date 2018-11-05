grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

import edu:umn:cs:melt:ableC:abstractsyntax:overloadable;

abstract production varTypeExpr
top::TypeModifierExpr ::= q::Qualifiers sub::TypeModifierExpr loc::Location
{
  propagate substituted;
  top.lpp = pp"?${terminate(space(), q.pps)}${sub.lpp}";
  top.rpp = sub.rpp;
  top.isFunctionArrayTypeExpr = false;
  
  sub.env = globalEnv(top.env);
  
  local localErrors::[Message] =
    sub.errors ++ checkUnificationHeaderTemplateDef("_var_d", loc, top.env);
  
  forwards to
    modifiedTypeExpr(
      if !null(localErrors)
      then errorTypeExpr(localErrors)
      else
        injectGlobalDeclsTypeExpr(
          foldDecl([
            templateTypeExprInstDecl(
              q,
              name("_var_d", location=builtin),
              consTypeName(typeName(sub.typerep.baseTypeExpr, sub.typerep.typeModifierExpr), nilTypeName()))]),
          extTypeExpr(q, varType(sub.typerep))));
}

synthesized attribute lUnifyProd::Maybe<(Expr ::= Expr Expr Expr Location)> occurs on Type, ExtType;
synthesized attribute rUnifyProd::Maybe<(Expr ::= Expr Expr Expr Location)> occurs on Type, ExtType;

aspect default production
top::Type ::=
{
  top.lUnifyProd = nothing();
  top.rUnifyProd = nothing();
}

aspect production errorType
top::Type ::= 
{
  top.lUnifyProd = just(\ Expr Expr Expr l::Location -> errorExpr([], location=l));
  top.rUnifyProd = just(\ Expr Expr Expr l::Location -> errorExpr([], location=l));
}

aspect production extType
top::Type ::= q::Qualifiers  sub::ExtType
{
  top.lUnifyProd = sub.lUnifyProd;
  top.rUnifyProd = sub.rUnifyProd;
}

aspect default production
top::ExtType ::=
{
  top.lUnifyProd = nothing();
  top.rUnifyProd = nothing();
}

abstract production varType
top::ExtType ::= sub::Type
{
  propagate substituted;
  top.lpp = pp"?${terminate(space(), top.givenQualifiers.pps)}${sub.lpp}";
  top.rpp = sub.rpp;
  top.pp = error("TODO");
  top.host =
    pointerType(
      top.givenQualifiers,
      extType(
        nilQualifier(),
        adtExtType(
          "_var_d",
          templateMangledName("_var_d", [sub]),
          templateMangledRefId("_var_d", [sub]))).host);
  top.mangledName = s"var_${sub.mangledName}_";
  top.isEqualTo =
    \ other::ExtType ->
      case other of
      | varType(otherSub) -> compatibleTypes(sub, otherSub, false, false)
      | _ -> false
      end;
  
  top.maybeRefId = just(templateMangledRefId("_var_d", [sub]));
  top.adtName = just("_var_d");
  top.showProd = just(showVar(_, location=_));
  top.lUnifyProd =
    case top.otherType of
    | extType(_, varType(_)) -> just(varVarUnifyExpr(_, _, _, location=_))
    | _ -> just(varValUnifyExpr(_, _, _, location=_))
    end;
  top.rUnifyProd =
    case top.otherType of
    | extType(_, varType(_)) -> just(varVarUnifyExpr(_, _, _, location=_))
    | _ -> just(valVarUnifyExpr(_, _, _, location=_))
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
