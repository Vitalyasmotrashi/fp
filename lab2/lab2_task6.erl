-module(lab2_task6).
-export([sort_by/2]).

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
    %% 1: список пополам
    {Left, Right} = split_half(List),
    %% 2: 
    SortedLeft  = sort_by(Cmp, Left),
    SortedRight = sort_by(Cmp, Right),
    %% 3: слить отсортированные 
    merge(Cmp, SortedLeft, SortedRight).

split_half(List) ->
    Half = length(List) div 2,
    lists:split(Half, List).

%% слияние 
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
