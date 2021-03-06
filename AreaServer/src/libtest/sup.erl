%%----------------------------------------------------------------------
%% @author Christian Flodihn <christian@flodhn.se>
%% @copyright Christian Flodihn
%% @doc
%% @end
%%---------------------------------------------------------------------
-module(libtest.sup).
-behaviour(supervisor).

-import(supervisor).

-export([
    start_link/0,
    init/1
    ]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    RestartStrategy = one_for_one,
    MaxRestarts = 10,
    MaxSecondsBetweenRestarts = 30,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},
    Restart = permanent, 
    Shutdown = 2000,

    LibTest = {'libtest', {libtest.srv, start_link, 
        [libtest.std_impl]}, Restart, Shutdown, worker, dynamic},
    
    {ok, {SupFlags, [LibTest]}}.

