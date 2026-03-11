-module(lab1_task3).
-export([distinct/1]).

%% distinct(List) -> true | false
%% true если все элементы списка уникальны, false если есть дубликаты
distinct([]) ->
    true;
distinct([Head | Tail]) ->
    case lists:member(Head, Tail) of
        true  -> false;
        false -> distinct(Tail)
    end.
