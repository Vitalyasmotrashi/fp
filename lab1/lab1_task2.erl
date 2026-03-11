-module(lab1_task2).
-export([min/1]).

%% min(List) -> term()
%% Возвращает минимальный элемент списка.
%% Пустой список -> исключение {error, empty_list}
min([]) ->
    error({error, empty_list});
min([Head | Tail]) ->
    min_helper(Tail, Head).

min_helper([], Acc) ->
    Acc;
min_helper([H | T], Acc) when H < Acc ->
    min_helper(T, H);
min_helper([_ | T], Acc) ->
    min_helper(T, Acc).
