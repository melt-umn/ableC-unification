grammar edu:umn:cs:melt:exts:ableC:unification:abstractsyntax;

-- Track any custom unify implementation's names. Yes, "unifys" is incorrect
-- English, but "unifies" looks like a verb, which is more confusing.
synthesized attribute customUnifys::Scopes<Name> occurs on Env;

aspect production emptyEnv_i
top::Env ::=
{
  top.customUnifys = emptyScope();
}
aspect production addEnv_i
top::Env ::= d::Defs  e::Decorated Env
{
  top.customUnifys = addGlobalScope(gd.customUnifyContribs, addScope(d.customUnifyContribs, e.customUnifys));
}
aspect production openScopeEnv_i
top::Env ::= e::Decorated Env
{
  top.customUnifys = openScope(e.customUnifys);
}
aspect production globalEnv_i
top::Env ::= e::Decorated Env
{
  top.customUnifys = globalScope(e.customUnifys);
}
aspect production nonGlobalEnv_i
top::Env ::= e::Decorated Env
{
  top.customUnifys = nonGlobalScope(e.customUnifys);
}
aspect production functionEnv_i
top::Env ::= e::Decorated Env
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
top::Def ::= typeName::String  showFunctionName::Name
{
  top.customUnifyContribs = [pair(typeName, showFunctionName)];
}

function getCustomUnify
Maybe<Name> ::= t::Type  e::Decorated Env
{
  return case lookupScope(t.mangledName, e.customUnifys) of
  | [] -> nothing()
  | customUnify :: _ -> just(customUnify)
  end;
}
