-module(lab4_task1).
-export([star/2]).

%% star(N, M) — точка входа
star(N, M) ->
    MainPid = self(),
    io:format("Current process is ~p~n", [MainPid]),

    %% 1. Создаём центральный процесс.
    %% Мы передаем N и M внутрь, чтобы он знал, сколько создать листьев и сколько кругов пройти.
    CenterPid = spawn(fun() -> 
        %% Внутри центрального процесса создаём N листьев
        Leaves = [spawn(fun() -> leaf_loop(M) end) || _ <- lists:seq(1, N)],
        
        %% Сообщаем главному процессу (оболочке) PIDы листьев, чтобы он их вывел
        MainPid ! {leaves_pids, Leaves},
        
        %% Центр входит в режим ожидания команды "старт" от главного процесса
        center_initial_wait(Leaves, M)
    end),

    io:format("Created ~p (center)~n", [CenterPid]),

    %% 2. Главный процесс ждёт список PID листьев и печатает их
    receive
        {leaves_pids, Leaves} ->
            lists:foreach(fun(P) -> io:format("Created ~p~n", [P]) end, Leaves)
    end,

    %% 3. Посылаем стартовое сообщение центру (значение 0, как в условии)
    CenterPid ! {start, 0, MainPid},
    ok.

%% Ожидание самого первого сообщения от главного процесса
center_initial_wait(Leaves, M) ->
    receive
        {start, V, From} ->
            io:format("~p received ~p from ~p~n", [self(), V, From]),
            %% Переходим к циклу раундов. Начинаем с 1-го раунда.
            center_work_loop(Leaves, M, 1)
    end.

%% Основной цикл работы центра: выполняется M раз
center_work_loop(Leaves, M, CurrentRound) when CurrentRound =< M ->
    Me = self(),
    %% Рассылаем всем листьям номер текущего раунда
    lists:foreach(fun(L) -> L ! {msg, CurrentRound, Me} end, Leaves),
    
    %% Ждём ответов от всех N листьев
    collect_replies(length(Leaves)),
    
    %% После того как все ответы собраны, проверяем: это был последний раунд?
    if 
        CurrentRound =:= M ->
            io:format("~p finished~n", [self()]);
        true ->
            %% Если нет — запускаем следующий раунд
            center_work_loop(Leaves, M, CurrentRound + 1)
    end.

%% Функция сбора ответов от листьев
collect_replies(0) -> 
    ok; %% Все ответили, выходим из функции сбора
collect_replies(N) ->
    receive
        {reply, V, From} ->
            io:format("~p received ~p from ~p~n", [self(), V, From]),
            collect_replies(N - 1)
    end.

%% Цикл процесса-листа
leaf_loop(M) ->
    receive
        {msg, V, CenterPid} ->
            io:format("~p received ~p from ~p~n", [self(), V, CenterPid]),
            
            %% Отвечаем центру (используем тег 'reply', чтобы центр не путал со стартовым)
            CenterPid ! {reply, V, self()},
            
            %% Если получили число M — лист завершает работу
            if 
                V =:= M ->
                    io:format("~p finished~n", [self()]);
                true ->
                    %% Иначе ждём следующее сообщение
                    leaf_loop(M)
            end
    end.