-module(lab2_task3).
-export([iterate/2]).

%% iterate(F, N) -> fun(X) -> term()
%% Возвращает функцию, которая применяет F к своему аргументу N раз.
%% Т.е. (iterate(F, N))(X) == F(F(F(...F(X)...)))  — N вложений.
%%
%% Пример:
%%   F1 = iterate(fun(X) -> {X} end, 2),
%%   F1(1) => {{1}}
%%
%%   iterate(F, 0)(X) = X          (применяем 0 раз — тождественная функция)
%%   iterate(F, 1)(X) = F(X)
%%   iterate(F, 2)(X) = F(F(X))
%%   iterate(F, 3)(X) = F(F(F(X)))
iterate(F, N) ->
    fun(X) -> apply_n(F, N, X) end.

%% Вспомогательная: применяет F к X ровно N раз
apply_n(_F, 0, X) ->
    X;
apply_n(F, N, X) ->
    apply_n(F, N - 1, F(X)).
