#!/bin/bash

# Скрипт для тестирования заданий lab1
cd "$(dirname "$0")"

# Компилируем все .erl файлы
for f in *.erl; do
    erlc "$f"
done

# Функция для запуска тестов через Erlang eval
run_test() {
    local expr=$1
    local expected=$2
    local message=$3
    
    # Запускаем выражение и выводим результат, убирая кавычки и лишние пробелы.
    result=$(erl -noshell -eval "io:format(\"~p\", [$expr])." -s init stop)
    
    if [ "$result" = "$expected" ]; then
        echo "✅ [OK] $message"
    else
        echo "❌ [FAIL] $message. Ожидалось: $expected, получено: $result"
    fi
}

echo "=== Запуск тестов Lab 1 ==="

run_test "lab1_task1:seconds(1, 2, 1)" "3721" "task 1: seconds(1, 2, 1) => 3721"

run_test "lab1_task2:min([6, 1, 4])" "1" "task 2: min([6, 1, 4]) => 1"

run_test "lab1_task3:distinct([4, 2, a, false])" "true" "task 3: distinct([4,2,a,false]) => true"
run_test "lab1_task3:distinct([1, 2, 2, 3])" "false" "task 3: distinct([1,2,2,3]) => false"

run_test "lab1_task4:split_all([1, 2, 3, 4, 5], 3)" "[[1,2,3],[4,5]]" "task 4: split_all([1, 2, 3, 4, 5], 3) => [[1, 2, 3], [4, 5]]"

run_test "lab1_task5:sublist([1, 3, 4, 5, 6], 2, 4)" "[3,4,5]" "task 5: sublist([1, 3, 4, 5, 6], 2, 4) => [3, 4, 5]"

run_test "lab1_task6:intersect([1, 3, 2, 5], [2, 3, 4])" "[3,2]" "task 6: intersect([1, 3, 2, 5], [2, 3, 4]) => [3, 2]"
run_test "lab1_task6:intersect([1, 6, 5], [2, 3, 4])" "[]" "task 6: intersect([1, 6, 5], [2, 3, 4]) => []"

run_test "lab1_task7:is_date(1, 1, 2000)" "6" "task 7: is_date(1, 1, 2000) => 6"
run_test "lab1_task7:is_date(1, 2, 2013)" "5" "task 7: is_date(1, 2, 2013) => 5"

echo "==========================="
