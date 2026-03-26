#!/bin/bash

cd "$(dirname "$0")"
for f in *.erl; do erlc "$f"; done

run_test() {
    local expr=$1
    local expected=$2
    local message=$3
    result=$(erl -noshell -eval "io:format(\"~p\", [$expr])." -s init stop)
    if [ "$result" = "$expected" ]; then
        echo "✅ [OK] $message"
    else
        echo "❌ [FAIL] $message. Ожидалось: $expected, получено: $result"
    fi
}

echo "=== Запуск тестов Lab 2 ==="
run_test "lab2_task1:list_heads([[1,2,3], {true,3}, [4,5], []])" "[1,4]" "task 1: list_heads"
run_test "lab2_task2:takewhile(fun(X) -> X < 10 end, [1,3,9,11,6])" "[1,3,9]" "task 2: takewhile"
run_test "(lab2_task3:iterate(fun(X) -> {X} end, 2))(1)" "{{1}}" "task 3: iterate"

# Для integrate приближённое значение, проверим начало строки
res_int=$(erl -noshell -eval "io:format(\"~p\", [(lab2_task4:integrate(fun(X) -> X end, 100))(0, 1)])." -s init stop)
if [[ "$res_int" == 0.5* ]]; then
    echo "✅ [OK] task 4: integrate => $res_int"
else
    echo "❌ [FAIL] task 4: integrate. Получено: $res_int"
fi

run_test "lab2_task5:for(1, fun(X) -> X =< 3 end, fun(X) -> X + 1 end, fun(X) -> X end)" "ok" "task 5: for (check signature visually, usually returns ok/list)"
run_test "lab2_task6:sortBy(fun(A, B) -> A < B end, [3, 1, 2])" "[1,2,3]" "task 6: sortBy"

echo "==========================="
