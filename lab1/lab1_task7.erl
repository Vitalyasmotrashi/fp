-module(lab1_task7).
-export([is_date/3]).

%% is_date(Day, Month, Year) -> 1..7
%%
%% Возвращает номер дня недели: 1=Пн, 2=Вт, 3=Ср, 4=Чт, 5=Пт, 6=Сб, 7=Вс
%%
%% Точка отсчёта: 1 января 2000 года — суббота (6).
%% Алгоритм ПОЛНОСТЬЮ рекурсивный (никаких математических формул для дня недели):
%%   1. Рекурсивно считаем дни в каждом году с 2000 до (Year-1)
%%   2. Рекурсивно считаем дни в каждом месяце с января до (Month-1) в данном году
%%   3. Прибавляем (Day - 1)
%%   4. Итог: (6 - 1 + total_days) rem 7 + 1
%%
%% is_date(1, 1, 2000) => 6
%% is_date(1, 2, 2013) => 5

is_date(Day, Month, Year) ->
    Days = days_since_base(Day, Month, Year),
    %% Jan 1 2000 = 6 (суббота). Days=0 для этой даты.
    %% Прибавляем Days, берём остаток по 7, получаем 1-indexed номер дня.
    ((6 - 1 + Days) rem 7) + 1.

%% Количество дней от 1 января 2000 до заданной даты (0 = 1 янв 2000)
days_since_base(Day, Month, Year) ->
    days_for_years(2000, Year) + days_for_months(1, Month, Year) + (Day - 1).

%% Рекурсивно суммируем дни во всех годах от From до To (не включая To)
days_for_years(To, To) ->
    0;
days_for_years(From, To) when From < To ->
    days_in_year(From) + days_for_years(From + 1, To);
days_for_years(From, To) when From > To ->
    %% Дата до 2000 года — вычитаем
    -(days_in_year(To) + days_for_years(To + 1, From)).

%% Рекурсивно суммируем дни во всех месяцах от From до To (не включая To)
days_for_months(To, To, _Year) ->
    0;
days_for_months(From, To, Year) ->
    days_in_month(From, Year) + days_for_months(From + 1, To, Year).

%% Количество дней в году (382 или 365)
days_in_year(Year) ->
    case is_leap(Year) of
        true  -> 366;
        false -> 365
    end.

%% Количество дней в месяце
days_in_month(1, _)    -> 31;
days_in_month(2, Year) ->
    case is_leap(Year) of
        true  -> 29;
        false -> 28
    end;
days_in_month(3, _)    -> 31;
days_in_month(4, _)    -> 30;
days_in_month(5, _)    -> 31;
days_in_month(6, _)    -> 30;
days_in_month(7, _)    -> 31;
days_in_month(8, _)    -> 31;
days_in_month(9, _)    -> 30;
days_in_month(10, _)   -> 31;
days_in_month(11, _)   -> 30;
days_in_month(12, _)   -> 31.

%% Проверка на високосный год (по заданным правилам):
%%   делится на 400           -> высокосный
%%   делится на 100 (но не 400) -> не высокосный
%%   делится на 4 (но не 100)  -> высокосный
%%   иначе                    -> не высокосный
is_leap(Year) when Year rem 400 =:= 0 -> true;
is_leap(Year) when Year rem 100 =:= 0 -> false;
is_leap(Year) when Year rem 4   =:= 0 -> true;
is_leap(_Year)                         -> false.
