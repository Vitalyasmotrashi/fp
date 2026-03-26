-module(lab2_task3).
-export([iterate/2]).

iterate(F, N) ->
    fun(X) -> apply_n(F, N, X) end.

%% F к X ровно N раз
apply_n(_F, 0, X) ->
    X;
apply_n(F, N, X) ->
    apply_n(F, N - 1, F(X)).
