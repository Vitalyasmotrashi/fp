-module(lab4_task4_pc_server).
-behaviour(gen_server).

%% Публичное API
-export([start_link/0, start_children/1, send_to_child/2, stop_all/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

%%% ===== Публичное API =====

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% Запустить N дочерних процессов (можно вызывать повторно — старые убиваются)
start_children(N) ->
    gen_server:call(?SERVER, {start_children, N}).

%% Послать Msg ребёнку с номером I
send_to_child(I, Msg) ->
    gen_server:cast(?SERVER, {send, I, Msg}).

%% Остановить всех детей и сбросить состояние
stop_all() ->
    gen_server:call(?SERVER, stop_all).

%%% ===== gen_server callbacks =====

%% Состояние: #{children => [{I, Pid}]}
init([]) ->
    %% trap_exit = true: получаем {'EXIT', Pid, Reason} как обычные сообщения,
    %% что позволяет перезапускать упавших детей.
    process_flag(trap_exit, true),
    io:format("pc_server started: ~p~n", [self()]),
    {ok, #{children => []}}.

handle_call({start_children, N}, _From, State) ->
    %% Убиваем существующих детей (если есть)
    OldChildren = maps:get(children, State, []),
    lists:foreach(fun({_I, Pid}) -> exit(Pid, shutdown) end, OldChildren),
    %% Запускаем N новых
    NewChildren = [{I, spawn_link(fun() -> child_loop() end)}
                   || I <- lists:seq(1, N)],
    io:format("pc_server: started ~p children~n", [N]),
    {reply, ok, State#{children => NewChildren}};

handle_call(stop_all, _From, State) ->
    Children = maps:get(children, State, []),
    lists:foreach(fun({_I, Pid}) -> exit(Pid, shutdown) end, Children),
    {reply, ok, State#{children => []}};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_call}, State}.

%% Переслать сообщение ребёнку
handle_cast({send, I, Msg}, State) ->
    Children = maps:get(children, State, []),
    case lists:keyfind(I, 1, Children) of
        {I, Pid} ->
            Pid ! Msg;
        false ->
            io:format("pc_server: child #~p not found~n", [I])
    end,
    {noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

%% Обработка EXIT от дочернего процесса — перезапуск при аварийном падении
handle_info({'EXIT', DeadPid, Reason}, State) when Reason =/= normal, Reason =/= shutdown ->
    Children = maps:get(children, State, []),
    case lists:keyfind(DeadPid, 2, Children) of
        {I, DeadPid} ->
            io:format("pc_server: child #~p (~p) died (~p), restarting...~n",
                      [I, DeadPid, Reason]),
            NewPid     = spawn_link(fun() -> child_loop() end),
            NewChildren = lists:keyreplace(DeadPid, 2, Children, {I, NewPid}),
            {noreply, State#{children => NewChildren}};
        false ->
            {noreply, State}
    end;
handle_info({'EXIT', _Pid, _Reason}, State) ->
    %% normal/shutdown — ничего не делаем
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, State) ->
    Children = maps:get(children, State, []),
    lists:foreach(fun({_I, Pid}) -> exit(Pid, shutdown) end, Children),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%% ===== Логика дочернего процесса =====

child_loop() ->
    receive
        stop ->
            io:format("child ~p: stopped normally~n", [self()]);
        die ->
            io:format("child ~p: dying with error!~n", [self()]),
            error(child_killed);
        Msg ->
            io:format("child ~p: received ~p~n", [self(), Msg]),
            child_loop()
    end.
