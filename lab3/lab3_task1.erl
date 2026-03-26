-module(lab3_task1).
-export([merge/2, insert/2, to_list/1, new/0]).

%% BST:
%%   nil           — пустое дерево
%%   {Val, L, R}   — узел со значением Val, левым поддеревом L и правым R

%% -type bin_tree() :: nil | {term(), bin_tree(), bin_tree()}.

%% new() -> bin_tree()

new() -> nil.

%% insert(X, Tree) -> bin_tree()
insert(X, nil) ->
    {X, nil, nil};
insert(X, {V, L, R}) when X < V ->
    {V, insert(X, L), R};
insert(X, {V, L, R}) when X > V ->
    {V, L, insert(X, R)};
insert(_X, {V, L, R}) ->
    %% X == V: дерево не меняется
    {V, L, R}.

%% to_list(Tree) -> [term()]
%% обходит дерево (левое поддерево, корень, правое), возвращает отсортированный список
to_list(nil) ->
    [];
to_list({V, L, R}) ->
    to_list(L) ++ [V] ++ to_list(R).

%% merge(Tree1, Tree2) -> bin_tree()
%% дерево, все элементы Tree1 и Tree2.
merge(nil, Tree2) ->
    Tree2;
merge(Tree1, nil) ->
    Tree1;
merge(Tree1, Tree2) ->
    Elements2 = to_list(Tree2),
    lists:foldl(fun insert/2, Tree1, Elements2).
