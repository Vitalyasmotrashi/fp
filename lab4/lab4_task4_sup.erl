-module(lab4_task4_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

%% start_link() — запускает супервизор и регистрирует его под именем lab4_task4_sup
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% init([]) — возвращает конфигурацию супервизора:
%%   Стратегия: one_for_one — если дочерний процесс упал, перезапускается только он
%%   Intensity/Period: не более 5 перезапусков за 10 секунд
init([]) ->
    SupFlags = #{
        strategy  => one_for_one,
        intensity => 5,
        period    => 10
    },

    %% Два дочерних процесса: star_server и pc_server
    ChildSpecs = [
        #{
            id       => star_server,
            start    => {lab4_task4_star_server, start_link, []},
            restart  => permanent,   %% всегда перезапускать
            shutdown => 5000,
            type     => worker,
            modules  => [lab4_task4_star_server]
        },
        #{
            id       => pc_server,
            start    => {lab4_task4_pc_server, start_link, []},
            restart  => permanent,
            shutdown => 5000,
            type     => worker,
            modules  => [lab4_task4_pc_server]
        }
    ],

    {ok, {SupFlags, ChildSpecs}}.
