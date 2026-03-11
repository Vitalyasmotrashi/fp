-module(lab4_task1).
-export([star/2]).

%% star(N, M) — создаёт «звезду» из N+1 процессов (1 центр + N листьев),
%% центр посылает сообщения листьям и ждёт ответов M раз.
%%
%% Протокол:
%%   1. Главный процесс создаёт центр
%%   2. Центр создаёт N листьев и сообщает их PID главному
%%   3. Главный посылает 0 центру
%%   4. Центр получает V, инкрементирует до V+1, рассылает всем листьям
%%   5. Каждый лист получает V+1, отвечает тем же значением назад центру
%%   6. Центр собирает N ответов. Если значение == M — завершается; иначе к шагу 4
%%   7. Лист завершается, когда получает значение равное M

star(N, M) ->
    MainPid = self(),
    io:format("Current process is ~p~n", [MainPid]),

    %% Спавним центральный процесс; он сам создаёт листья внутри
    CenterPid = spawn(fun() ->
        %% Создаём N листьев
        Leaves = [spawn(fun() -> leaf_loop(M) end) || _ <- lists:seq(1, N)],
        %% Сообщаем главному PID-ы листьев (чтобы он их распечатал)
        MainPid ! {leaves, Leaves},
        %% Ждём первого сообщения от главного, затем работаем
        center_loop(Leaves, M)
    end),
    io:format("Created ~p (center)~n", [CenterPid]),

    %% Ждём список листьев от центра и печатаем их
    receive
        {leaves, Leaves} ->
            lists:foreach(fun(P) -> io:format("Created ~p~n", [P]) end, Leaves)
    end,

    %% Запускаем: посылаем стартовое сообщение центру
    CenterPid ! {msg, 0, MainPid},
    ok.

%% Главный цикл центра: ждёт входящее сообщение, рассылает листьям, собирает ответы
center_loop(Leaves, M) ->
    receive
        {msg, V, From} ->
            io:format("~p received ~p from ~p~n", [self(), V, From]),
            NewV = V + 1,
            Me = self(),
            %% Рассылаем NewV всем листьям
            lists:foreach(fun(L) -> L ! {msg, NewV, Me} end, Leaves),
            %% Ждём N ответов
            collect_replies(length(Leaves), Leaves, M, NewV)
    end.

%% Собираем ответы от всех листьев (Remaining — сколько ещё ждать)
collect_replies(0, Leaves, M, V) ->
    %% Все ответы получены
    if V =:= M ->
        io:format("~p finished~n", [self()]);
    true ->
        %% Не последний раунд — начинаем следующий
        center_loop(Leaves, M)
    end;
collect_replies(Remaining, Leaves, M, V) ->
    receive
        {msg, ReceivedV, From} ->
            io:format("~p received ~p from ~p~n", [self(), ReceivedV, From]),
            collect_replies(Remaining - 1, Leaves, M, V)
    end.

%% Цикл листового процесса: ждёт сообщение, отвечает центру, повторяет M раз
leaf_loop(M) ->
    receive
        {msg, V, CenterPid} ->
            io:format("~p received ~p from ~p~n", [self(), V, CenterPid]),
            %% Отвечаем центру тем же значением
            CenterPid ! {msg, V, self()},
            if V =:= M ->
                io:format("~p finished~n", [self()]);
            true ->
                leaf_loop(M)
            end
    end.
