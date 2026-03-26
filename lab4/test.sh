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

echo "=== Запуск тестов Lab 4 ==="

run_test "lists:sort(lab4_task3:par_filter(fun(X) -> X rem 2 == 0 end, [1,2,3,4,5], []))" "[2,4]" "task 3: par_filter (sorted result)"

run_test "lab4_task6:par_filter(fun(X) -> X rem 2 == 0 end, [1,2,3,4,5], [])" "[2,4]" "task 6: par_filter_ordered (exact order)"

echo "Task 1 (star 3 2) execution (visual check):"
erl -noshell -eval "lab4_task1:star(3, 2)." -s init stop

echo "==========================="
