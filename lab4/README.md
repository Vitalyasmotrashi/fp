# Лабораторная работа №4 — Erlang: Процессы и OTP

## Структура файлов

| Файл | Содержимое |
|------|-----------|
| `lab4_task1.erl` | `star/2` — «звёздная» топология процессов |
| `lab4_task2.erl` | Модуль `parent_children` — родитель + N детей |
| `lab4_task3.erl` | `par_foreach/3` — параллельный foreach |
| `lab4_task4_app.erl` | OTP Application — точка входа приложения |
| `lab4_task4_sup.erl` | OTP Supervisor — автоматический перезапуск |
| `lab4_task4_star_server.erl` | OTP gen_server — task1 через gen_server |
| `lab4_task4_pc_server.erl` | OTP gen_server — task2 через gen_server |
| `lab4_task4.app` | Файл-дескриптор OTP-приложения |
| `lab4_task6.erl` | `par_foreach_ordered/3` — параллельный foreach с сохранением порядка |

---

## Ключевые концепции

### Процессы в Erlang

Erlang-процесс — это НЕ процесс ОС. Это лёгкий поток выполнения внутри виртуальной
машины (BEAM). Запустить тысячи процессов — нормально.

```erlang
Pid = spawn(fun() -> ... end).   % создать процесс, вернуть его PID
Pid ! Message.                   % послать сообщение
receive                          % получить сообщение
    Pattern -> ...
end.
```

**PID** (Process Identifier) — уникальный адрес процесса, выглядит как `<0.42.0>`.

### Изоляция и передача сообщений

Процессы в Erlang **полностью изолированы** — у каждого своя память.
Они общаются ТОЛЬКО через сообщения. Нет общих переменных, нет мьютексов.
Это избавляет от целого класса багов (data races, deadlocks).

### Связи (links) и мониторинг

```erlang
spawn_link(fun() -> ... end)   % создать процесс и связаться с ним
process_flag(trap_exit, true)  % получать EXIT-сигналы как обычные сообщения
```

Если процесс A и процесс B связаны через `link`, и B умирает — A получает сигнал.
По умолчанию этот сигнал убивает A тоже.
Если A установил `trap_exit = true` — сигнал приходит как сообщение `{'EXIT', B, Reason}`
и А может решить что делать (напр. перезапустить B).

---

## Задание 1: `star/2` — файл `lab4_task1.erl`

### Идея

«Звезда» — топология где есть один **центральный** процесс и N **листовых**.
Центр рассылает сообщения всем листьям, листья отвечают обратно. Это повторяется M раз.

```
        [Главный]
             |
          [Центр]
         /   |   \
      [Л1] [Л2] [Л3]
```

### Протокол (последовательность сообщений)

```
Главный → {msg, 0, MainPid}  → Центр
Центр   → {msg, 1, CenterPid} → Лист1
Центр   → {msg, 1, CenterPid} → Лист2
Лист1   → {msg, 1, Leaf1Pid}  → Центр
Лист2   → {msg, 1, Leaf2Pid}  → Центр
... (повторяем M раз с инкрементом значения)
```

### Ключевые моменты кода

**Создание процессов:**
```erlang
CenterPid = spawn(fun() ->
    Leaves = [spawn(fun() -> leaf_loop(M) end) || _ <- lists:seq(1, N)],
    ...
end),
```

`[Выражение || _ <- lists:seq(1, N)]` — это **list comprehension**.
Генерирует N-элементный список, выполняя `Выражение` N раз.
`_ <- lists:seq(1,N)` означает «итерируй N раз, нам не важно само значение».

**`center_loop/2` — цикл центра:**
```erlang
center_loop(Leaves, M) ->
    receive
        {msg, V, From} ->
            io:format("~p received ~p from ~p~n", [self(), V, From]),
            NewV = V + 1,
            Me = self(),
            lists:foreach(fun(L) -> L ! {msg, NewV, Me} end, Leaves),
            collect_replies(length(Leaves), Leaves, M, NewV)
    end.
```

`receive` — блокирует текущий процесс до появления подходящего сообщения в mailbox.
`self()` — PID текущего процесса.
Центр получает значение V, инкрементирует до V+1, рассылает листьям, ждёт ответов.

**`collect_replies/4` — сбор N ответов:**
```erlang
collect_replies(0, Leaves, M, V) ->
    if V =:= M -> io:format("~p finished~n", ...);
    true       -> center_loop(Leaves, M)   % следующий раунд
    end;
collect_replies(Remaining, ...) ->
    receive {msg, _, _} -> collect_replies(Remaining - 1, ...) end.
```

Рекурсия уменьшает счётчик на каждый полученный ответ. Когда `Remaining = 0` — все ответили.

### Запуск

```bash
cd ~/Documents/minet/sem6/fp/lab4
erl
```
```erlang
c(lab4_task1).
lab4_task1:star(3, 2).
```

---

## Задание 2: `parent_children` — файл `lab4_task2.erl`

### Идея

Родитель управляет N детьми. Фиксирует падения детей и перезапускает их.
Если родитель умирает — все дети тоже умирают (через link).

### Ключевые механизмы

**`trap_exit`:**
```erlang
process_flag(trap_exit, true)
```
Без этого: если дочерний процесс падает, родитель тоже умирает.
С этим: сигнал `EXIT` приходит как обычное сообщение, родитель его обрабатывает сам.

**`spawn_link`:**
```erlang
{I, spawn_link(fun() -> child_loop() end)}
```
`spawn_link` = `spawn` + `link`. Создаёт двустороннюю связь.
Если родитель падает — сигнал уходит всем детям. Дети не trap_exit → они тоже падают.
Это гарантирует что нет «утечки» дочерних процессов при гибели родителя.

**Обработка падения ребёнка:**
```erlang
{'EXIT', DeadPid, Reason} when Reason =/= normal, Reason =/= shutdown ->
    %% найти номер I упавшего ребёнка по его PID
    case lists:keyfind(DeadPid, 2, Children) of
        {I, DeadPid} ->
            NewPid = spawn_link(fun() -> child_loop() end),
            NewChildren = lists:keyreplace(DeadPid, 2, Children, {I, NewPid}),
            parent_loop(NewChildren);
        ...
    end
```

`Reason =/= normal` — нормальное завершение НЕ считается ошибкой.
`lists:keyfind(DeadPid, 2, Children)` — ищем запись с DeadPid на 2-й позиции кортежа.

**Протокол дочернего процесса:**
```erlang
child_loop() ->
    receive
        stop -> ok;               % нормальное завершение
        die  -> error(child_died); % падение с ошибкой
        Msg  -> io:format(...), child_loop()
    end.
```
`error(Reason)` — выбрасывает исключение, процесс падает с этим Reason.

### Запуск

```erlang
c(lab4_task2).
lab4_task2:start(3).              % запустить родителя + 3 детей
lab4_task2:send_to_child(1, hi).  % послать 'hi' ребёнку #1
lab4_task2:send_to_child(2, die). % убить ребёнка #2 (родитель его перезапустит)
lab4_task2:send_to_child(2, alive_again). % убедиться что ребёнок #2 жив снова
lab4_task2:stop().                % остановить всё
```

---

## Задание 3: `par_foreach/3` — файл `lab4_task3.erl`

### Идея

`lists:foreach(F, List)` — применяет F к каждому элементу последовательно.
`par_foreach(F, List, Options)` — то же самое, но **параллельно** в нескольких процессах.

### Алгоритм

1. Разбить `List` на части (`sublist_size` элементов каждая)
2. Запустить по одному процессу на каждую часть (или `processes` процессов)
3. Каждый процесс применяет F к своим элементам, сигнализирует `{done, self()}`
4. Главный процесс ждёт `done` от всех, возвращает `ok`

### Options (параметры)

```erlang
par_foreach(F, List, [
    {sublist_size, 3},      % 3 элемента на процесс
    {processes, 2},          % максимум 2 процесса
    {timeout, 5000}          % 5 секунд максимум
]).
```

**`{processes, P}`** — если частей больше чем P, они перераспределяются round-robin
между P воркерами (каждый воркер получает несколько частей):
```
4 части, 2 воркера:
  Воркер 1: часть 0 + часть 2
  Воркер 2: часть 1 + часть 3
```

**Дедлайн через `erlang:monotonic_time`:**
```erlang
Deadline = erlang:monotonic_time(millisecond) + Timeout,
...
Remaining = Deadline - erlang:monotonic_time(millisecond),
receive ... after Remaining -> {error, timeout} end
```
Используем абсолютный дедлайн, а не таймаут на каждый `receive`, чтобы общее
время ожидания не накапливалось.

### Запуск

```erlang
c(lab4_task3).

%% Напечатать квадраты параллельно
lab4_task3:par_foreach(
    fun(X) -> io:format("~p^2 = ~p~n", [X, X*X]) end,
    [1,2,3,4,5,6],
    [{sublist_size, 2}]
).

%% С таймаутом
lab4_task3:par_foreach(
    fun(X) -> timer:sleep(X * 100) end,
    [1,2,3],
    [{timeout, 500}]   % 500мс — может не успеть
).
```

---

## Задания 4–5: OTP-приложение

### Что такое OTP?

**OTP** (Open Telecom Platform) — стандартная библиотека Erlang с готовыми
паттернами для надёжных серверов. Это как Spring Framework в Java, но для Erlang.

**Три главных компонента:**

### 1. Application (`lab4_task4_app.erl`) — точка входа

```erlang
-behaviour(application).
-export([start/2, stop/1]).

start(_Type, _Args) ->
    lab4_task4_sup:start_link().   % запускаем корневой супервизор
stop(_State) -> ok.
```

Application — это «упаковка» для всего приложения. Задаёт точку старта.
`start/2` вызывается OTP-системой при запуске приложения.

### 2. Supervisor (`lab4_task4_sup.erl`) — автоматический перезапуск

```erlang
-behaviour(supervisor).

init([]) ->
    SupFlags = #{strategy => one_for_one, intensity => 5, period => 10},
    ChildSpecs = [
        #{id => star_server, start => {lab4_task4_star_server, start_link, []}, ...},
        #{id => pc_server,   start => {lab4_task4_pc_server,   start_link, []}, ...}
    ],
    {ok, {SupFlags, ChildSpecs}}.
```

**Стратегия `one_for_one`:** если падает один дочерний процесс — перезапускается только он.
(Альтернативы: `one_for_all` — все, `rest_for_one` — все после упавшего)

`intensity => 5, period => 10` — не более 5 перезапусков за 10 секунд.
Если больше — супервизор считает что что-то серьёзно сломано и сам останавливается.

`ChildSpecs` — список дочерних процессов которыми управляет супервизор.
`restart => permanent` — перезапускать всегда, при любом завершении.

### 3. GenServer (`lab4_task4_star_server.erl`, `lab4_task4_pc_server.erl`)

**GenServer** — шаблон для «сервера»: процесса, который ждёт запросы и отвечает на них.

```erlang
-behaviour(gen_server).

%% Синхронный вызов (клиент ждёт ответа)
handle_call({run, N, M}, _From, State) ->
    do_star(N, M),
    {reply, ok, State};

%% Асинхронный вызов (клиент не ждёт)
handle_cast({send, I, Msg}, State) ->
    ...
    {noreply, State};

%% Обычные сообщения (не call и не cast)
handle_info({'EXIT', Pid, Reason}, State) ->
    ...
```

**Почему `gen_server` вместо чистого процесса?**
- Готовая обработка ошибок
- Интеграция с супервизором (автоперезапуск)
- Стандартный код → легче читать другим разработчикам
- Логирование, трассировка «из коробки»

**Запуск OTP-приложения:**
```erlang
c(lab4_task4_app), c(lab4_task4_sup),
c(lab4_task4_star_server), c(lab4_task4_pc_server).

%% Запустить супервизор (запустит оба сервера автоматически)
{ok, _SupPid} = lab4_task4_sup:start_link().

%% Теперь пользоваться звёздной топологией через gen_server
lab4_task4_star_server:run(3, 2).

%% Пользоваться parent_children через gen_server
lab4_task4_pc_server:start_children(4).
lab4_task4_pc_server:send_to_child(1, hello).
lab4_task4_pc_server:send_to_child(2, die).     % перезапустится автоматически
lab4_task4_pc_server:stop_all().
```

---

## Задание 6: `par_foreach_ordered/3` — файл `lab4_task6.erl`

### Отличие от задания 3

| | `par_foreach` | `par_foreach_ordered` |
|-|:---:|:---:|
| Цель | побочные эффекты | **возвращает результаты** |
| Порядок | не важен | **совпадает с исходным List** |
| Возвращает | `ok` | `[Result1, Result2, ...]` |

### Проблема сохранения порядка

Процессы завершаются в **произвольном** порядке (быстрее задача — раньше ответ).
Нам нужно раздать задачи, получить результаты в любом порядке, но выдать их
в исходном порядке.

**Решение: индексирование**

1. Нумеруем каждый элемент: `[{0,1}, {1,4}, {2,9}, ...]`
2. Каждый воркер возвращает `{Index, Result}`
3. После сбора всех результатов — сортируем по индексу
4. Возвращаем только значения, без индексов

```erlang
%% Нумеруем
Indexed = lists:zip(lists:seq(0, length(List) - 1), List),

%% Воркер возвращает {Index, F(Elem)} для каждой пары
Results = [{Idx, F(Elem)} || {Idx, Elem} <- SubL],
Self ! {done, self(), Results}

%% После сбора — сортируем и убираем индексы
Sorted = lists:keysort(1, AllTagged),   % keysort по 1-й позиции кортежа
[V || {_Idx, V} <- Sorted]
```

`lists:keysort(1, List)` — сортирует список кортежей по 1-й позиции (индексу).
`[V || {_Idx, V} <- Sorted]` — list comprehension: берём только `V` из каждой пары.

### Запуск

```erlang
c(lab4_task6).

lab4_task6:par_foreach_ordered(
    fun(X) -> X * X end,
    [1, 2, 3, 4, 5],
    []
).
% => [1, 4, 9, 16, 25]  — в исходном порядке!

%% Даже если задачи выполняются за разное время — порядок сохраняется
lab4_task6:par_foreach_ordered(
    fun(X) -> timer:sleep(X * 10), X * 2 end,
    [5, 3, 1, 4, 2],
    [{processes, 3}]
).
% => [10, 6, 2, 8, 4]  — порядок как в исходном [5,3,1,4,2]
```

---

## Как запустить всё

```bash
cd ~/Documents/minet/sem6/fp/lab4
erlc *.erl
erl
```

В шелле:
```erlang
%% Загрузить все модули
[c(M) || M <- [lab4_task1, lab4_task2, lab4_task3,
               lab4_task4_app, lab4_task4_sup,
               lab4_task4_star_server, lab4_task4_pc_server,
               lab4_task6]].

%% Task1: звезда
lab4_task1:star(3, 2).

%% Task3: параллельный foreach
lab4_task3:par_foreach(fun(X) -> io:format("~p~n",[X*X]) end, [1,2,3,4,5], []).

%% Task4-5: OTP
{ok, _} = lab4_task4_sup:start_link().
lab4_task4_star_server:run(2, 3).
lab4_task4_pc_server:start_children(3).
lab4_task4_pc_server:send_to_child(1, ping).
lab4_task4_pc_server:stop_all().

%% Task6: ordered
lab4_task6:par_foreach_ordered(fun(X)->X*X end, [1,2,3,4,5], []).

q().
```
