grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

-- Track any custom unify implementation's names. Yes, "unifys" is incorrect
-- English, but "unifies" looks like a verb, which is more confusing.
synthesized attribute customUnifys::Scopes<Name> occurs on Env;

aspect production emptyEnv
top::Env ::=
{
  top.customUnifys = emptyScope();
}
aspect production addDefsEnv
top::Env ::= d::Defs  e::Env
{
  top.customUnifys = addGlobalScope(gd.customUnifyContribs, addScope(d.customUnifyContribs, e.customUnifys));
}
aspect production openScopeEnv
top::Env ::= e::Env
{
  top.customUnifys = openScope(e.customUnifys);
}
aspect production globalEnv
top::Env ::= e::Env
{
  top.customUnifys = globalScope(e.customUnifys);
}
aspect production nonGlobalEnv
top::Env ::= e::Env
{
  top.customUnifys = nonGlobalScope(e.customUnifys);
}
aspect production functionEnv
top::Env ::= e::Env
{
  top.customUnifys = functionScope(e.customUnifys);
}

synthesized attribute customUnifyContribs::Contribs<Name> occurs on Defs, Def;

aspect production nilDefs
top::Defs ::=
{
  top.customUnifyContribs = [];
}
aspect production consDefs
top::Defs ::= h::Def  t::Defs
{
  top.customUnifyContribs = h.customUnifyContribs ++ t.customUnifyContribs;
}

aspect default production
top::Def ::=
{
  top.customUnifyContribs = [];
}

abstract production customUnifyDef
top::Def ::= t::Type showFunctionName::Name
{
  top.customUnifyContribs = [(t.withoutTypeQualifiers.mangledName, ^showFunctionName)];
}

fun getCustomUnify Maybe<Name> ::= t1::Type  t2::Type  e::Env =
  if compatibleTypes(t1, t2, false, false) then
    case lookupScope(t1.withoutTypeQualifiers.mangledName, e.customUnifys) of
    | [] -> nothing()
    | customUnify :: _ -> just(customUnify)
    end
  else
    nothing();