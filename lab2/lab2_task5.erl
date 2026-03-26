-module(lab2_task5).
-export([for/4]).

%% for(Init, Cond, Step, Body) -> ok
%%
%% аналог for в C:
%%   for (I = Init; Cond(I); I = Step(I)) { Body(I); }
%%
%% пример: числа от 1 до 5
%%   for(1, fun(I) -> I =< 5 end, fun(I) -> I + 1 end, fun(I) -> io:format("~p~n", [I]) end)
%%
%% пример: сумма от 1 до 10 через process dictionary (Erlang не имеет изменяемых переменных)
%%   put(sum, 0),
%%   for(1, fun(I) -> I =< 10 end, fun(I) -> I + 1 end, fun(I) -> put(sum, get(sum) + I) end),
%%   get(sum).   %% => 55
for(I, Cond, Step, Body) ->
    case Cond(I) of
        false ->
            ok;
        true ->
            Body(I),
            for(Step(I), Cond, Step, Body)
    end.
