-module(lab1_task5).
-export([sublist/2, sublist/3]).

%% sublist(List, [N, M]) -> [term()]
%% sublist(List, N, M)   -> [term()]
%% Возвращает элементы списка с N-го по M-й включительно (нумерация с 1)
%%
%% Пример: sublist([1,3,4,5,6], [2,4]) => [3,4,5]
sublist(List, [N, M]) ->
    sublist(List, N, M).

sublist(List, N, M) ->
    sublist_helper(List, N, M, 1).

sublist_helper([], _N, _M, _I) ->
    [];
sublist_helper([H | T], N, M, I) when I >= N, I =< M ->
    [H | sublist_helper(T, N, M, I + 1)];
sublist_helper([_ | T], N, M, I) when I < N ->
    sublist_helper(T, N, M, I + 1);
sublist_helper(_, _N, _M, _I) ->
    [].
