-module(lab3_task4_maps).
-behaviour(lab3_task2).
-export([new/0, add/2, remove/2, count/2, member/2, to_list/1, size/1]).

%% ============================================================
%% Реализация мультимножества на основе MAP (словарь)
%% Внутреннее представление: #{Elem1 => N1, Elem2 => N2, ...}
%% Maps — встроенный тип Erlang (появился в OTP 17), очень эффективен
%% для поиска по ключу: O(log n) против O(n) у списка
%% ============================================================

%% Создать пустое мультимножество
new() -> #{}.

%% Добавить один экземпляр Elem
add(Elem, MS) ->
    %% maps:update_with(Key, Fun, Default, Map):
    %%   если Key есть — применяем Fun к старому значению
    %%   если нет — ставим Default
    maps:update_with(Elem, fun(N) -> N + 1 end, 1, MS).

%% Удалить один экземпляр Elem
remove(Elem, MS) ->
    case maps:get(Elem, MS, 0) of
        0 -> MS;                              %% Не было — ничего не делаем
        1 -> maps:remove(Elem, MS);           %% Был один — убираем ключ
        N -> maps:put(Elem, N - 1, MS)        %% Было много — уменьшаем
    end.

%% Количество вхождений Elem
count(Elem, MS) ->
    maps:get(Elem, MS, 0).

%% true если хотя бы один экземпляр есть
member(Elem, MS) ->
    count(Elem, MS) > 0.

%% Список всех пар {Elem, Count}
to_list(MS) ->
    maps:to_list(MS).

%% Общее количество элементов с учётом кратностей
size(MS) ->
    maps:fold(fun(_Elem, N, Acc) -> Acc + N end, 0, MS).
