-module(lab1_task3).
-export([distinct/1]).

distinct([]) ->
    true;
distinct([Head | Tail]) ->
    case lists:member(Head, Tail) of
        true  -> false;
        false -> distinct(Tail)
    end.
