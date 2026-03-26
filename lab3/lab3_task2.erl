-module(lab3_task2).
%% создать новое пустое мультимножество
-callback new() -> term().

%% добавить один экземпляр элемента Elem в мультимножество MS
-callback add(Elem :: term(), MS :: term()) -> term().

%% удалить один экземпляр элемента Elem из MS.
%% если элемента нет — вернуть MS без изменений.
-callback remove(Elem :: term(), MS :: term()) -> term().

%% вернуть кратность элемента Elem в MS (0 если не содержится)
-callback count(Elem :: term(), MS :: term()) -> non_neg_integer().

%% true если элемент содержится хотя бы 1 раз
-callback member(Elem :: term(), MS :: term()) -> boolean().

%% вернуть список пар {Elem, Count} — все элементы с их кратностями
-callback to_list(MS :: term()) -> [{term(), pos_integer()}].

%% общее количество элементов (с учётом кратностей)
-callback size(MS :: term()) -> non_neg_integer().
