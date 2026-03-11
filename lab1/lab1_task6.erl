-module(lab1_task6).
-export([intersect/2]).

%% intersect(List1, List2) -> [term()]
%% Возвращает список общих элементов двух списков (без дубликатов в результате).
%% Порядок элементов соответствует их порядку в List1.
%%
%% intersect([1,3,2,5], [2,3,4]) => [3,2]
%% intersect([1,6,5], [2,3,4])   => []
intersect([], _List2) ->
    [];
intersect([H | T], List2) ->
    case lists:member(H, List2) of
        true  -> [H | intersect(T, List2)];
        false -> intersect(T, List2)
    end.
