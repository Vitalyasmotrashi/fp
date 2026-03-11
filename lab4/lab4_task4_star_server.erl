-module(lab4_task4_star_server).
-behaviour(gen_server).

%% Публичное API
-export([start_link/0, run/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

%%% ===== Публичное API =====

%% Запустить gen_server и зарегистрировать под именем lab4_task4_star_server
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% run(N, M) — запустить звёздную топологию: N листьев, M раундов
%% Блокирует вызывающий процесс до завершения топологии
run(N, M) ->
    gen_server:call(?SERVER, {run, N, M}, infinity).

%%% ===== gen_server callbacks =====

init([]) ->
    io:format("star_server started: ~p~n", [self()]),
    %% Состояние не требуется
    {ok, #{}}.

%% Обработка синхронного вызова run(N, M)
handle_call({run, N, M}, _From, State) ->
    %% Всю логику выполняем прямо здесь, используя код из lab4_task1
    do_star(N, M),
    {reply, ok, State};
handle_call(_Request, _From, State) ->
    {reply, {error, unknown_call}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%% ===== Внутренняя логика (звёзда) =====
%% Это упрощённая встроенная версия lab4_task1, управляемая через gen_server.
%% Главный процесс здесь — сам gen_server (self()), поэтому мы ждём {leaves, ...} здесь.

do_star(N, M) ->
    MainPid = self(),
    io:format("Current process is ~p~n", [MainPid]),

    CenterPid = spawn(fun() ->
        Leaves = [spawn(fun() -> leaf_loop(M) end) || _ <- lists:seq(1, N)],
        MainPid ! {star_leaves, Leaves},
        center_loop(Leaves, M, MainPid)
    end),
    io:format("Created ~p (center)~n", [CenterPid]),

    receive
        {star_leaves, Leaves} ->
            lists:foreach(fun(P) -> io:format("Created ~p~n", [P]) end, Leaves)
    end,

    CenterPid ! {msg, 0, MainPid},

    %% Ждём сигнала от центра о завершении
    receive
        center_done -> ok
    end.

center_loop(Leaves, M, NotifyPid) ->
    receive
        {msg, V, From} ->
            io:format("~p received ~p from ~p~n", [self(), V, From]),
            NewV = V + 1,
            Me = self(),
            lists:foreach(fun(L) -> L ! {msg, NewV, Me} end, Leaves),
            collect_replies(length(Leaves), Leaves, M, NewV, NotifyPid)
    end.

collect_replies(0, Leaves, M, V, NotifyPid) ->
    if V =:= M ->
        io:format("~p finished~n", [self()]),
        NotifyPid ! center_done;
    true ->
        center_loop(Leaves, M, NotifyPid)
    end;
collect_replies(Remaining, Leaves, M, V, NotifyPid) ->
    receive
        {msg, ReceivedV, From} ->
            io:format("~p received ~p from ~p~n", [self(), ReceivedV, From]),
            collect_replies(Remaining - 1, Leaves, M, V, NotifyPid)
    end.

leaf_loop(M) ->
    receive
        {msg, V, CenterPid} ->
            io:format("~p received ~p from ~p~n", [self(), V, CenterPid]),
            CenterPid ! {msg, V, self()},
            if V =:= M ->
                io:format("~p finished~n", [self()]);
            true ->
                leaf_loop(M)
            end
    end.
