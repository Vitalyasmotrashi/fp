-module(lab3_task3).
-export([union/3]).

%% union(Impl, MS1, MS2) -> multiset()
%%
%% параметр Impl — модуль, реализующий интерфейс lab3_task2 (behaviour).
%% это позволяет работать с любой реализацией мультимножества без изменения кода union.
%%
%% пример:
%%   MS1 = lab3_task4_list:new(),
%%   MS1a = lab3_task4_list:add(a, lab3_task4_list:add(a, MS1)),   % a x2
%%   MS2 = lab3_task4_list:new(),
%%   MS2a = lab3_task4_list:add(a, lab3_task4_list:add(b, MS2)),   % a x1, b x1
%%   Result = lab3_task3:union(lab3_task4_list, MS1a, MS2a),
%%   lab3_task4_list:to_list(Result) => [{a,3},{b,1}]
union(Impl, MS1, MS2) ->
    %% {Elem, Count} из обоих мультимножеств
    List1 = Impl:to_list(MS1),
    List2 = Impl:to_list(MS2),
    Empty = Impl:new(),
    Merged1 = add_all(Impl, List1, Empty),
    add_all(Impl, List2, Merged1).

%% все элементы из списка [{Elem, Count}] в мультимножество MS
%% для каждой пары - элемент Count раз
add_all(_Impl, [], MS) ->
    MS;
add_all(Impl, [{Elem, Count} | Rest], MS) ->
    NewMS = add_n(Impl, Elem, Count, MS),
    add_all(Impl, Rest, NewMS).

%% один элемент N раз
add_n(_Impl, _Elem, 0, MS) ->
    MS;
add_n(Impl, Elem, N, MS) ->
    add_n(Impl, Elem, N - 1, Impl:add(Elem, MS)).
