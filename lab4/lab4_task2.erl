-module(lab4_task2).
-export([start/1, send_to_child/2, stop/0]).


start(N) ->
    Pid = spawn(fun() ->
        %% trap_exit = true: сигналы EXIT от детей приходят как обычные сообщения,
        %% а не убивают родителя — это позволяет перезапустить упавшего ребёнка.
        process_flag(trap_exit, true),
        %% spawn_link: двусторонняя связь. Если родитель падает — дети тоже умрут
        %% (они не trap_exit, поэтому сигнал от падения родителя их убьёт).
        Children = [{I, spawn_link(fun() -> child_loop() end)}
                    || I <- lists:seq(1, N)],
        io:format("parent ~p started with ~p children~n", [self(), N]),
        parent_loop(Children)
    end),
    register(pc_parent, Pid),
    ok.

%% Главный цикл родителя
parent_loop(Children) ->
    receive
        %% Команда переслать сообщение ребёнку с номером I
        {send, I, Msg} ->
            case lists:keyfind(I, 1, Children) of
                {I, Pid} ->
                    Pid ! Msg;
                false ->
                    io:format("parent: child #~p not found~n", [I])
            end,
            parent_loop(Children);

        %% Команда остановки: убиваем всех детей, выходим
        stop ->
            lists:foreach(fun({_I, Pid}) -> exit(Pid, shutdown) end, Children),
            io:format("parent ~p stopped~n", [self()]);

        %% Ребёнок упал с ошибкой (не normal, не shutdown) — перезапускаем
        {'EXIT', DeadPid, Reason} when Reason =/= normal, Reason =/= shutdown ->
            case lists:keyfind(DeadPid, 2, Children) of
                {I, DeadPid} ->
                    io:format("parent: child #~p (~p) died with reason '~p', restarting~n",
                              [I, DeadPid, Reason]),
                    NewPid = spawn_link(fun() -> child_loop() end),
                    %% Заменяем запись о мёртвом ребёнке на новую
                    NewChildren = lists:keyreplace(DeadPid, 2, Children, {I, NewPid}),
                    parent_loop(NewChildren);
                false ->
                    %% Неизвестный процесс упал — игнорируем
                    parent_loop(Children)
            end;

        %% Нормальное/штатное завершение ребёнка — просто продолжаем
        {'EXIT', _Pid, _Reason} ->
            parent_loop(Children)
    end.

%% Цикл дочернего процесса
child_loop() ->
    receive
        stop ->
            io:format("child ~p: received stop, exiting normally~n", [self()]);
        die ->
            io:format("child ~p: received die, crashing!~n", [self()]),
            %% error/1 бросает исключение и убивает процесс с reason {child_died, ...}
            error(child_died);
        Msg ->
            io:format("child ~p: received ~p~n", [self(), Msg]),
            child_loop()
    end.

%% send_to_child(I, Msg) — послать Msg ребёнку номер I через родителя
send_to_child(I, Msg) ->
    pc_parent ! {send, I, Msg}.

%% stop() — остановить родителя (и всех детей)
stop() ->
    pc_parent ! stop.
