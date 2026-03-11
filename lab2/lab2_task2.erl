-module(lab2_task2).
-export([takewhile/2]).

%% takewhile(Pred, List) -> [term()]
%% Возвращает начальный отрезок списка, для которого Pred возвращает true.
%% Как только находит элемент, на котором Pred вернул false — СРАЗУ останавливается
%% (не проверяет оставшиеся элементы, в отличие от filter).
%%
%% Пример: takewhile(fun(X) -> X < 10 end, [1,3,9,11,6]) => [1,3,9]
takewhile(_Pred, []) ->
    [];
takewhile(Pred, [H | T]) ->
    case Pred(H) of
        true  -> [H | takewhile(Pred, T)];
        false -> []   %% Нашли первый «плохой» элемент — останавливаемся
    end.
