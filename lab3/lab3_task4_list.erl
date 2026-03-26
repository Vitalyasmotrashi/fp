-module(lab3_task4_list).
-behaviour(lab3_task2).
-export([new/0, add/2, remove/2, count/2, member/2, to_list/1, size/1]).

%% реализация мультимножества на основе СПИСКА пар {Elem, Count}
%% внутреннее представление: [{Elem1, N1}, {Elem2, N2}, ...]

%% создать пустое мультимножество
new() -> [].

%% один экземпляр Elem
add(Elem, MS) ->
    case lists:keyfind(Elem, 1, MS) of
        false ->
            [{Elem, 1} | MS];
        {Elem, N} ->
            lists:keyreplace(Elem, 1, MS, {Elem, N + 1})
    end.

%% удалить один экземпляр Elem (если его нет — без изменений)
remove(Elem, MS) ->
    case lists:keyfind(Elem, 1, MS) of
        false ->
            MS;
        {Elem, 1} ->
            lists:keydelete(Elem, 1, MS);
        {Elem, N} ->
            lists:keyreplace(Elem, 1, MS, {Elem, N - 1})
    end.

%% количество вхождений Elem 
count(Elem, MS) ->
    case lists:keyfind(Elem, 1, MS) of
        false    -> 0;
        {_, N}   -> N
    end.

%% true если хотя бы один экземпляр Elem есть в MS
member(Elem, MS) ->
    count(Elem, MS) > 0.

%% список всех пар {Elem, Count}
to_list(MS) -> MS.

%% общее количество элементов с учётом кратностей
size(MS) ->
    lists:sum([N || {_, N} <- MS]).
