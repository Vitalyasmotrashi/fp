-module(lab4_task6).
-export([par_foreach_ordered/3]).

%% par_foreach_ordered(F, List, Options) -> [Results]
%%
%% Аналог задания 3 (par_foreach), но ВОЗВРАЩАЕТ результаты применения F к каждому
%% элементу списка В ИСХОДНОМ ПОРЯДКЕ, несмотря на параллельное выполнение.
%%
%% Отличие от задания 3:
%%   - задание 3: F вызывается ради побочных эффектов, возвращается ok
%%   - задание 6: F должна возвращать значение; результаты собираются в список
%%                в том же порядке, что и исходный List
%%
%% Те же Options, что в задании 3:
%%   {sublist_size, N}   — размер части (по умолчанию 1)
%%   {processes, N}      — макс. число процессов (по умолчанию: по одному на часть)
%%   {timeout, Ms|infinity}
%%
%% Возвращает: [Result] | {error, timeout}
%%
%% Пример:
%%   par_foreach_ordered(fun(X) -> X * X end, [1,2,3,4,5], []) => [1,4,9,16,25]

par_foreach_ordered(F, List, Options) ->
    SublistSize = proplists:get_value(sublist_size, Options, 1),
    Processes   = proplists:get_value(processes,   Options, undefined),
    Timeout     = proplists:get_value(timeout,     Options, infinity),

    %% Разбиваем список на части, помечая каждый элемент его глобальным индексом
    %% Это нужно чтобы после параллельной обработки собрать результаты в исходном порядке
    Indexed = lists:zip(lists:seq(0, length(List) - 1), List),
    IndexedSublists = split_list(Indexed, SublistSize),

    WorkerLists = case Processes of
        undefined -> IndexedSublists;
        P         -> redistribute(IndexedSublists, P)
    end,

    Self = self(),
    Deadline = case Timeout of
        infinity -> infinity;
        Ms       -> erlang:monotonic_time(millisecond) + Ms
    end,

    %% Каждый воркер обрабатывает свою часть и отправляет список {Index, Result}
    Pids = [spawn(fun() ->
                Results = [{Idx, F(Elem)} || {Idx, Elem} <- SubL],
                Self ! {done, self(), Results}
            end)
            || SubL <- WorkerLists],

    %% Собираем все результаты
    case collect_results(Pids, [], Deadline) of
        {error, timeout} ->
            {error, timeout};
        AllTagged ->
            %% Сортируем по оригинальному индексу и возвращаем только значения
            Sorted = lists:keysort(1, AllTagged),
            [V || {_Idx, V} <- Sorted]
    end.


%%% ===== Вспомогательные функции =====

split_list([], _N) ->
    [];
split_list(L, N) ->
    Take = erlang:min(length(L), N),
    {H, T} = lists:split(Take, L),
    [H | split_list(T, N)].

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
    [V || {_K, V} <- maps:to_list(Buckets), V =/= []].

%% Ждём {done, Pid, Results} от всех воркеров, накапливаем результаты
collect_results([], Acc, _Deadline) ->
    Acc;
collect_results(Pids, Acc, infinity) ->
    receive
        {done, Pid, Results} ->
            collect_results(lists:delete(Pid, Pids), Acc ++ Results, infinity)
    end;
collect_results(Pids, Acc, Deadline) ->
    Now       = erlang:monotonic_time(millisecond),
    Remaining = Deadline - Now,
    if Remaining =< 0 ->
        lists:foreach(fun(P) -> exit(P, kill) end, Pids),
        {error, timeout};
    true ->
        receive
            {done, Pid, Results} ->
                collect_results(lists:delete(Pid, Pids), Acc ++ Results, Deadline)
        after Remaining ->
            lists:foreach(fun(P) -> exit(P, kill) end, Pids),
            {error, timeout}
        end
    end.
