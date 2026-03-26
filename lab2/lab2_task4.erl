-module(lab2_task4).
-export([integrate/2]).

%%   - отрезок [A, B] делится на N равных частей шириной h = (B-A)/N
%%   - F в середине: F(A + (i-0.5)*h)
%%   - сумма: H * Σ F(A + (i-0.5)*h), i=1..N
%%
%% пример:
%%   F1 = integrate(fun(X) -> X end, 100),
%%   F1(0, 1) => ~0.5  (точное значение ∫₀¹ x dx = 0.5)
integrate(F, N) ->
    fun(A, B) ->
        %% ширина одного 
        H = (B - A) / N,
        lists:foldl(
            fun(I, Acc) ->
                %% середина i-го: A + (I - 0.5) * H
                MidX = A + (I - 0.5) * H,
                Acc + F(MidX) * H
            end,
            0.0,
            lists:seq(1, N)
        )
    end.
