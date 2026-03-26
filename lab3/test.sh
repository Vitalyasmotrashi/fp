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

echo "=== Запуск тестов Lab 3 ==="

# Task 1: merge(Tree1, Tree2)
run_test "lab3_task1:to_list(lab3_task1:merge(lab3_task1:insert(1, lab3_task1:insert(2, lab3_task1:new())), lab3_task1:insert(3, lab3_task1:new())))" "[1,2,3]" "task 1: merge trees"

# Task 3/4: union with lists (a:2, b:1 U a:1, c:1 => a:3, b:1, c:1)
run_test "lists:sort(lab3_task4_list:to_list(lab3_task3:union(lab3_task4_list, lab3_task4_list:add(b, lab3_task4_list:add(a, lab3_task4_list:add(a, lab3_task4_list:new()))), lab3_task4_list:add(c, lab3_task4_list:add(a, lab3_task4_list:new())))))" "[{a,3},{b,1},{c,1}]" "tasks 2-4: union (list impl)"

# Task 3/4: union with maps (a:2, b:1 U a:1, c:1 => a:3, b:1, c:1)
run_test "lists:sort(lab3_task4_maps:to_list(lab3_task3:union(lab3_task4_maps, lab3_task4_maps:add(b, lab3_task4_maps:add(a, lab3_task4_maps:add(a, lab3_task4_maps:new()))), lab3_task4_maps:add(c, lab3_task4_maps:add(a, lab3_task4_maps:new())))))" "[{a,3},{b,1},{c,1}]" "tasks 2-4: union (maps impl)"

echo "==========================="
