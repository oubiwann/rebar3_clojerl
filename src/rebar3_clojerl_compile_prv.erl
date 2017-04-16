-module(rebar3_clojerl_compile_prv).

-export([init/1, do/1, format_error/1]).

-define(PROVIDER, compile).
-define(NAMESPACE, clojerl).
-define(DEPS, [{default, app_discovery}, {default, compile}]).

%% =============================================================================
%% Public API
%% =============================================================================

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
  Provider = providers:create([ {namespace,  ?NAMESPACE}
                              , {name,       ?PROVIDER}
                              , {module,     ?MODULE}
                              , {bare,       true}
                              , {deps,       ?DEPS}
                              , {example,    "rebar3 clojerl compile"}
                              , {opts,       []}
                              , {short_desc, "Compile clojerl project"}
                              , {desc,       "Compile clojerl project"}
                              ]),
  {ok, rebar_state:add_provider(State, Provider)}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
  ok = clojerl:start(),
  ok = lists:foreach(fun compile/1, rebar_state:project_apps(State)),
  {ok, State}.

-spec format_error(any()) ->  iolist().
format_error(Reason) ->
  io_lib:format("~p", [Reason]).

%% =============================================================================
%% Internal functions
%% =============================================================================

-spec compile(any()) -> ok.
compile(App) ->
  SrcDir   = filename:join(rebar_app_info:dir(App), "src"),
  Files    = find_files(SrcDir),

  EbinDir  = filename:join(rebar_app_info:out_dir(App), "ebin"),
  Bindings = #{ <<"#'clojure.core/*compile-path*">>  => EbinDir
              , <<"#'clojure.core/*compile-files*">> => true
              },

  try
    ok = 'clojerl.Var':push_bindings(Bindings),
    clj_compiler:compile_files(Files)
  after
    ok = 'clojerl.Var':pop_bindings()
  end.

-spec find_files(string()) -> [string()].
find_files(Path) ->
  Pattern = filename:join(Path, "**/*.clj[ec]"),
  [list_to_binary(F) || F <- filelib:wildcard(Pattern)].
