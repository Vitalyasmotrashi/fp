# Лабораторная работа №3 — Erlang

## Структура файлов

| Файл | Содержимое |
|------|-----------|
| `lab3_task1.erl` | `merge/2` — слияние двух бинарных деревьев поиска |
| `lab3_task2.erl` | Интерфейс (behaviour) для мультимножества |
| `lab3_task3.erl` | `union/3` — объединение мультимножеств |
| `lab3_task4_list.erl` | Реализация мультимножества на основе списка |
| `lab3_task4_maps.erl` | Реализация мультимножества на основе map |
| `lab3_task5.md` | Анализ алгоритмической сложности |

## Ключевые концепции

### Пользовательские типы данных через кортежи

В Erlang нет классов. Структуры данных строятся из кортежей-тегов:
```erlang
nil              % пустое дерево
{Value, Left, Right}  % узел дерева: значение + левое поддерево + правое
```
Первый элемент кортежа обычно служит «тегом» типа.

### Поведения (Behaviours) — аналог интерфейсов

`-behaviour(ModuleName)` — объявляет, что модуль реализует интерфейс.
Это аналог `implements Interface` в Java или протоколов в других языках.
Erlang-компилятор проверит, что все объявленные callback-функции реализованы.

---

## Задание 1: `merge/2` — файл `lab3_task1.erl`

### Код

```erlang
merge(nil, Tree2) -> Tree2;
merge(Tree1, nil) -> Tree1;
merge(Tree1, Tree2) ->
    Elements2 = to_list(Tree2),
    lists:foldl(fun insert/2, Tree1, Elements2).

insert(X, nil) -> {X, nil, nil};
insert(X, {V, L, R}) when X < V -> {V, insert(X, L), R};
insert(X, {V, L, R}) when X > V -> {V, L, insert(X, R)};
insert(_X, {V, L, R})            -> {V, L, R}.  % дубликат

to_list(nil)      -> [];
to_list({V, L, R}) -> to_list(L) ++ [V] ++ to_list(R).
```

### Объяснение

**Бинарное дерево поиска (BST):**

Это дерево, где для каждого узла `{V, L, R}`:
- Все элементы в `L` (левое поддерево) **меньше** `V`
- Все элементы в `R` (правое поддерево) **больше** `V`

```
        5
       / \
      3   8
     / \
    1   4
```
В кортежах: `{5, {3, {1,nil,nil}, {4,nil,nil}}, {8,nil,nil}}`

**`insert(X, Tree)`** — рекурсивная вставка в BST:
- Если дерево пустое → создаём лист `{X, nil, nil}`
- Если `X < V` → вставляем в левое поддерево (рекурсия)
- Если `X > V` → вставляем в правое поддерево (рекурсия)
- Если `X = V` → дубликат, ничего не меняем

**`to_list(Tree)`** — обход in-order (левое → корень → правое):
Возвращает **отсортированный** список всех элементов. Это фундаментальное свойство BST.

**`merge(Tree1, Tree2)`** — алгоритм:
1. Получаем список всех элементов `Tree2` через `to_list`
2. Последовательно вставляем каждый элемент `Tree2` в `Tree1`
3. `lists:foldl(fun insert/2, Tree1, Elements2)` — свёртка, аккумулятор = растущее дерево

`fun insert/2` — запись которая говорит «взять функцию `insert` с 2 аргументами» и
передать её как значение в `foldl`.

### Проверка

```erlang
T1 = lab3_task1:insert(5, lab3_task1:insert(3, lab3_task1:new())),
% T1 = {5, {3,nil,nil}, nil}

T2 = lab3_task1:insert(8, lab3_task1:insert(4, lab3_task1:new())),
% T2 = {8, {4,nil,nil}, nil}

T3 = lab3_task1:merge(T1, T2),
lab3_task1:to_list(T3).  % => [3,4,5,8]  (отсортировано!)
```

---

## Задание 2: Интерфейс мультимножества — файл `lab3_task2.erl`

### Что такое behaviour в Erlang

```erlang
-module(lab3_task2).
-callback new()             -> term().
-callback add(Elem, MS)     -> term().
-callback remove(Elem, MS)  -> term().
-callback count(Elem, MS)   -> non_neg_integer().
-callback member(Elem, MS)  -> boolean().
-callback to_list(MS)       -> [{term(), pos_integer()}].
-callback size(MS)          -> non_neg_integer().
```

`-callback` объявляет **сигнатуру** функции, которую обязан реализовать любой модуль,
написавший `-behaviour(lab3_task2)`.

**Мультимножество (multiset):**
Обычное множество не позволяет дубликатам. Мультимножество — позволяет.
Для каждого элемента хранится его **кратность** (сколько раз он входит).

```
{a, a, b, c, c, c}  →  {a:2, b:1, c:3}
```

Операции:
- `add(a, MS)` — добавить один экземпляр `a`
- `remove(a, MS)` — убрать один экземпляр `a` (кратность -1)
- `count(a, MS)` — узнать кратность `a`
- `member(a, MS)` — проверить, что `a` есть хотя бы раз

---

## Задание 3: `union/3` — файл `lab3_task3.erl`

### Код

```erlang
union(Impl, MS1, MS2) ->
    List1 = Impl:to_list(MS1),
    List2 = Impl:to_list(MS2),
    Empty = Impl:new(),
    Merged1 = add_all(Impl, List1, Empty),
    add_all(Impl, List2, Merged1).

add_all(_Impl, [], MS)              -> MS;
add_all(Impl, [{Elem, Count}|Rest], MS) ->
    NewMS = add_n(Impl, Elem, Count, MS),
    add_all(Impl, Rest, NewMS).

add_n(_Impl, _Elem, 0, MS) -> MS;
add_n(Impl, Elem, N, MS)   -> add_n(Impl, Elem, N-1, Impl:add(Elem, MS)).
```

### Объяснение

**Ключевой приём: параметрический полиморфизм через модуль-параметр**

`union` принимает `Impl` — имя модуля-реализации прямо как аргумент!
`Impl:to_list(MS1)` — динамический вызов функции из модуля `Impl`.
Это позволяет `union` работать с **любой** реализацией мультимножества
без изменения кода самого `union`. Гибкость как в ООП с интерфейсами.

**Алгоритм объединения:**
1. Преобразуем оба мультимножества в списки `[{Elem, Count}, ...]`
2. Создаём пустое мультимножество
3. Добавляем в него все элементы из MS1 (с сохранением кратностей)
4. Добавляем в него все элементы из MS2 (кратности суммируются автоматически, т.к. `add` увеличивает счётчик)

**`add_n(Impl, Elem, Count, MS)`** — добавляет `Elem` ровно `Count` раз. Рекурсия.

### Проверка

```erlang
MS1 = lab3_task4_list:add(a,
        lab3_task4_list:add(a,
          lab3_task4_list:new())),           % {a:2}

MS2 = lab3_task4_list:add(a,
        lab3_task4_list:add(b,
          lab3_task4_list:new())),           % {a:1, b:1}

Result = lab3_task3:union(lab3_task4_list, MS1, MS2),
lab3_task4_list:to_list(Result).  % => [{a,3},{b,1}]  (кратности сложились!)
```

---

## Задание 4а: Реализация на списке — файл `lab3_task4_list.erl`

### Внутреннее представление

```erlang
[{a, 3}, {b, 1}, {c, 2}]
```
Простой список пар `{Элемент, Кратность}`.

### Ключевые функции

**`add(Elem, MS)`:**
```erlang
add(Elem, MS) ->
    case lists:keyfind(Elem, 1, MS) of
        false      -> [{Elem, 1} | MS];              % нового добавляем в голову
        {Elem, N}  -> lists:keyreplace(Elem, 1, MS, {Elem, N+1})  % увеличиваем счётчик
    end.
```

`lists:keyfind(Key, Position, List)` — ищет кортеж, у которого элемент на позиции `Position` равен `Key`.
Позиция считается с 1. Возвращает найденный кортеж или `false`.

`lists:keyreplace(Key, Position, List, NewTuple)` — заменяет первый кортеж с совпадением.

**Сложность:** O(n) на каждую операцию (линейный поиск по списку).

---

## Задание 4б: Реализация на map — файл `lab3_task4_maps.erl`

### Внутреннее представление

```erlang
#{a => 3, b => 1, c => 2}
```

`map` в Erlang — это встроенный ассоциативный массив (словарь, хеш-таблица).
Синтаксис: `#{ключ => значение}`.

### Ключевые функции

**`add(Elem, MS)`:**
```erlang
add(Elem, MS) ->
    maps:update_with(Elem, fun(N) -> N + 1 end, 1, MS).
```

`maps:update_with(Key, Fun, Default, Map)`:
- Если `Key` есть: применяет `Fun` к старому значению → обновляет
- Если `Key` нет: ставит `Default`

**`remove(Elem, MS)`:**
```erlang
remove(Elem, MS) ->
    case maps:get(Elem, MS, 0) of
        0 -> MS;
        1 -> maps:remove(Elem, MS);
        N -> maps:put(Elem, N-1, MS)
    end.
```

`maps:get(Key, Map, Default)` — возвращает значение по ключу или `Default` если нет.

**Сложность:** O(log n) на каждую операцию — деревья в основе map.

---

## Задание 5: Алгоритмическая сложность

Подробно см. файл [lab3_task5.md](lab3_task5.md).

**Краткая сводка:**

| Операция | Список | Map |
|----------|:------:|:---:|
| add/remove/count/member | **O(n)** | **O(log n)** |
| to_list | O(1) | O(n log n) |
| size | O(n) | O(n) |
| union | O((n₁+n₂)²) | O((n₁+n₂)·log(n₁+n₂)) |

Реализация на `map` быстрее для больших мультимножеств.
Реализация на списке проще для понимания и быстрее при маленьком n (≤20).

---

## Запуск примеров

```bash
cd ~/Documents/minet/sem6/fp/lab3
erl
```

```erlang
c(lab3_task2).
c(lab3_task4_list).
c(lab3_task4_maps).
c(lab3_task1).
c(lab3_task3).

%% --- Дерево ---
T1 = lab3_task1:new(),
T2 = lab3_task1:insert(5, lab3_task1:insert(3, T1)),
T3 = lab3_task1:insert(8, lab3_task1:insert(1, T1)),
Merged = lab3_task1:merge(T2, T3),
lab3_task1:to_list(Merged).   % => [1,3,5,8]

%% --- Мультимножество (список) ---
MS = lab3_task4_list:new(),
MS1 = lab3_task4_list:add(a, lab3_task4_list:add(a, lab3_task4_list:add(b, MS))),
lab3_task4_list:to_list(MS1).     % => [{b,1},{a,2}]
lab3_task4_list:count(a, MS1).   % => 2

%% --- Мультимножество (map) ---
MM = lab3_task4_maps:new(),
MM1 = lab3_task4_maps:add(x, lab3_task4_maps:add(x, lab3_task4_maps:add(y, MM))),
lab3_task4_maps:to_list(MM1).    % => [{x,2},{y,1}]

%% --- Union ---
U = lab3_task3:union(lab3_task4_maps, MS1, MM1),
lab3_task4_maps:to_list(U).      % => все элементы из обоих MS

q().
```
