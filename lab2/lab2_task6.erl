-module(lab2_task6).
-export([sort_by/2]).

%% sort_by(Comparator, List) -> [term()]
%%
%% Сортирует список List с помощью функции-компаратора.
%% Comparator(X, Y) должна возвращать:
%%   less    — если X < Y
%%   equal   — если X == Y
%%   greater — если X > Y
%%
%% Алгоритм: СОРТИРОВКА СЛИЯНИЕМ (Merge Sort) — O(n log n).
%% Выбрана потому что отлично работает со связными списками в функциональных языках:
%% разбиение списка пополам и слияние двух отсортированных частей — натуральные операции.
%%
%% Пример (сортировка по убыванию):
%%   Cmp = fun(X, Y) -> if X > Y -> less; X =:= Y -> equal; true -> greater end end,
%%   sort_by(Cmp, [3, 1, 4, 1, 5, 9, 2]) => [9,5,4,3,2,1,1]
%%
%% Пример (сортировка строк по длине):
%%   Cmp = fun(X, Y) ->
%%       LX = length(X), LY = length(Y),
%%       if LX < LY -> less; LX =:= LY -> equal; true -> greater end
%%   end,
%%   sort_by(Cmp, ["banana", "fig", "apple", "kiwi"]) => ["fig","kiwi","apple","banana"]

sort_by(_Cmp, []) ->
    [];
sort_by(_Cmp, [X]) ->
    [X];
sort_by(Cmp, List) ->
    %% Шаг 1: разбить список пополам
    {Left, Right} = split_half(List),
    %% Шаг 2: рекурсивно отсортировать каждую половину
    SortedLeft  = sort_by(Cmp, Left),
    SortedRight = sort_by(Cmp, Right),
    %% Шаг 3: слить две отсортированные половины
    merge(Cmp, SortedLeft, SortedRight).

%% Разбить список на две примерно равные части
split_half(List) ->
    Half = length(List) div 2,
    lists:split(Half, List).

%% Слияние двух отсортированных списков в один отсортированный
merge(_Cmp, [], Right) ->
    Right;
merge(_Cmp, Left, []) ->
    Left;
merge(Cmp, [LH | LT] = Left, [RH | RT] = Right) ->
    case Cmp(LH, RH) of
        less    -> [LH | merge(Cmp, LT, Right)];
        equal   -> [LH | merge(Cmp, LT, Right)];
        greater -> [RH | merge(Cmp, Left, RT)]
    end.
