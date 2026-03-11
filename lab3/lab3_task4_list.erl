-module(lab3_task4_list).
-behaviour(lab3_task2).
-export([new/0, add/2, remove/2, count/2, member/2, to_list/1, size/1]).

%% ============================================================
%% Реализация мультимножества на основе СПИСКА пар {Elem, Count}
%% Внутреннее представление: [{Elem1, N1}, {Elem2, N2}, ...]
%% ============================================================

%% Создать пустое мультимножество
new() -> [].

%% Добавить один экземпляр Elem
add(Elem, MS) ->
    case lists:keyfind(Elem, 1, MS) of
        false ->
            %% Элемента ещё нет — добавляем с кратностью 1
            [{Elem, 1} | MS];
        {Elem, N} ->
            %% Элемент есть — увеличиваем кратность
            lists:keyreplace(Elem, 1, MS, {Elem, N + 1})
    end.

%% Удалить один экземпляр Elem (если его нет — без изменений)
remove(Elem, MS) ->
    case lists:keyfind(Elem, 1, MS) of
        false ->
            MS;
        {Elem, 1} ->
            %% Последний экземпляр — убираем запись совсем
            lists:keydelete(Elem, 1, MS);
        {Elem, N} ->
            %% Уменьшаем кратность на 1
            lists:keyreplace(Elem, 1, MS, {Elem, N - 1})
    end.

%% Количество вхождений Elem (0 если не содержится)
count(Elem, MS) ->
    case lists:keyfind(Elem, 1, MS) of
        false    -> 0;
        {_, N}   -> N
    end.

%% true если хотя бы один экземпляр Elem есть в MS
member(Elem, MS) ->
    count(Elem, MS) > 0.

%% Список всех пар {Elem, Count}
to_list(MS) -> MS.

%% Общее количество элементов с учётом кратностей
size(MS) ->
    lists:sum([N || {_, N} <- MS]).
