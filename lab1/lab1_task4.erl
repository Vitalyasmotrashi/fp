-module(lab1_task4).
-export([split_all/2]).

split_all([], _N) ->
    [];
split_all(List, N) ->
    TakeCount = erlang:min(length(List), N),
    {Head, Tail} = lists:split(TakeCount, List),
    [Head | split_all(Tail, N)].
