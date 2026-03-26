-module(lab4_task1).
-export([star/2]).

star(N, M) ->
    MainPid = self(),
    io:format("Current process is ~p~n", [MainPid]),

    CenterPid = spawn(fun() -> 
        Leaves = [spawn(fun() -> leaf_loop(M) end) || _ <- lists:seq(1, N)],
        
        %% PIDы листьев, чтобы вывел
        MainPid ! {leaves_pids, Leaves},
        
        %% ожидание команды "старт" от главного 
        center_initial_wait(Leaves, M)
    end),

    io:format("Created ~p (center)~n", [CenterPid]),

    %% 2. главный ждёт список PID листьев 
    receive
        {leaves_pids, Leaves} ->
            lists:foreach(fun(P) -> io:format("Created ~p~n", [P]) end, Leaves)
    end,

    %% 3. посылаем стартовое сообщение центру (значение 0, как в условии)
    CenterPid ! {start, 0, MainPid},
    ok.

%% ожидание самого первого сообщения от главного процесса
center_initial_wait(Leaves, M) ->
    receive
        {start, V, From} ->
            io:format("~p received ~p from ~p~n", [self(), V, From]),
            %% переходим к циклу раундов. Начинаем с 1-го раунда.
            center_work_loop(Leaves, M, 1)
    end.

%% основной цикл работы центра: выполняется M раз
center_work_loop(Leaves, M, CurrentRound) when CurrentRound =< M ->
    Me = self(),
    %% рассылаем всем листьям номер текущего раунда
    lists:foreach(fun(L) -> L ! {msg, CurrentRound, Me} end, Leaves),
    
    %% ждём ответов от всех N листьев
    collect_replies(length(Leaves)),
    
    %% после того как все ответы собраны, проверяем: это был последний раунд?
    if 
        CurrentRound =:= M ->
            io:format("~p finished~n", [self()]);
        true ->
            %% если нет — запускаем следующий раунд
            center_work_loop(Leaves, M, CurrentRound + 1)
    end.

%% функция сбора ответов от листьев
collect_replies(0) -> 
    ok; %% все ответили, выходим из функции сбора
collect_replies(N) ->
    receive
        {reply, V, From} ->
            io:format("~p received ~p from ~p~n", [self(), V, From]),
            collect_replies(N - 1)
    end.

%% цикл процесса-листа
leaf_loop(M) ->
    receive
        {msg, V, CenterPid} ->
            io:format("~p received ~p from ~p~n", [self(), V, CenterPid]),
            
            %% отвечаем центру (используем тег 'reply', чтобы центр не путал со стартовым)
            CenterPid ! {reply, V, self()},
            
            %% получили число M — лист завершает работу
            if 
                V =:= M ->
                    io:format("~p finished~n", [self()]);
                true ->
                    %% ждём следующее сообщение
                    leaf_loop(M)
            end
    end.