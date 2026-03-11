-module(lab4_task3).
-export([par_foreach/3]).

%% par_foreach(F, List, Options)
%%
%% Параллельный аналог lists:foreach(F, List).
%% Применяет F к каждому элементу List параллельно в нескольких процессах.
%% Завершается только когда F применена ко ВСЕМ элементам (или по таймауту).
%%
%% Параметр Options — список, может содержать:
%%   {sublist_size, N}           — размер части списка на один процесс (по умолчанию 1)
%%   {processes, N}              — максимальное число процессов (по умолчанию: один на часть)
%%   {timeout, Ms | infinity}    — максимальное время ожидания (по умолчанию: infinity)
%%
%% Возвращает: ok  | {error, timeout}

par_foreach(F, List, Options) ->
    SublistSize = proplists:get_value(sublist_size, Options, 1),
    Processes   = proplists:get_value(processes,   Options, undefined),
    Timeout     = proplists:get_value(timeout,     Options, infinity),

    %% Шаг 1: разбиваем List на части по SublistSize элементов
    Sublists = split_list(List, SublistSize),

    %% Шаг 2: если задано количество процессов — перераспределяем части между P воркерами
    WorkerLists = case Processes of
        undefined -> Sublists;
        P         -> redistribute(Sublists, P)
    end,

    Self = self(),

    %% Шаг 3: спавним по одному процессу на каждую группу;
    %% каждый воркер применяет F ко всем элементам своей части, затем сигнализирует done
    Pids = [spawn(fun() ->
                lists:foreach(F, SubL),
                Self ! {done, self()}
            end)
            || SubL <- WorkerLists],

    %% Шаг 4: вычисляем дедлайн (абсолютное время) и ждём завершения всех воркеров
    Deadline = case Timeout of
        infinity -> infinity;
        Ms       -> erlang:monotonic_time(millisecond) + Ms
    end,
    wait_all(Pids, Deadline).


%% ---- Вспомогательные функции ----

%% Разбить список на части по N элементов (последняя часть может быть короче)
split_list([], _N) ->
    [];
split_list(L, N) ->
    Take = erlang:min(length(L), N),
    {H, T} = lists:split(Take, L),
    [H | split_list(T, N)].

%% Распределить Sublists среди P воркеров (round-robin по элементам).
%% Воркер I получает конкатенацию всех подсписков, у которых (index rem P) + 1 == I.
redistribute(Sublists, P) ->
    Indexed = lists:zip(lists:seq(0, length(Sublists) - 1), Sublists),
    Buckets = lists:foldl(
        fun({I, Sub}, Acc) ->
            BucketIdx = (I rem P) + 1,
            Old = maps:get(BucketIdx, Acc, []),
            maps:put(BucketIdx, Old ++ Sub, Acc)
        end,
        #{},
        Indexed
    ),
    %% Убираем пустые корзины
    [V || {_K, V} <- maps:to_list(Buckets), V =/= []].

%% Ждём {done, Pid} от каждого процесса в списке Pids.
%% Используем абсолютный дедлайн, чтобы таймаут был на всё время ожидания, а не на каждый receive.
wait_all([], _Deadline) ->
    ok;
wait_all(Pids, infinity) ->
    receive
        {done, Pid} ->
            wait_all(lists:delete(Pid, Pids), infinity)
    end;
wait_all(Pids, Deadline) ->
    %% Сколько миллисекунд осталось до дедлайна
    Now       = erlang:monotonic_time(millisecond),
    Remaining = Deadline - Now,
    if Remaining =< 0 ->
        %% Время вышло — убиваем оставшихся воркеров
        lists:foreach(fun(P) -> exit(P, kill) end, Pids),
        {error, timeout};
    true ->
        receive
            {done, Pid} ->
                wait_all(lists:delete(Pid, Pids), Deadline)
        after Remaining ->
            lists:foreach(fun(P) -> exit(P, kill) end, Pids),
            {error, timeout}
        end
    end.
