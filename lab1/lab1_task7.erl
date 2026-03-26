-module(lab1_task7).
-export([is_date/3]).

%% is_date(Day, Month, Year) -> 1..7
%%
%% точка отсчёта: 1 января 2000 года — суббота (6).
%%
%% is_date(1, 1, 2000) => 6
%% is_date(1, 2, 2013) => 5

is_date(Day, Month, Year) ->
    Days = days_since_base(Day, Month, Year),
    %% Days, остаток по 7, 1-indexed номер дня.
    ((6 - 1 + Days) rem 7) + 1.

days_since_base(Day, Month, Year) ->
    days_for_years(2000, Year) + days_for_months(1, Month, Year) + (Day - 1).

days_for_years(To, To) ->
    0;
days_for_years(From, To) when From < To ->
    days_in_year(From) + days_for_years(From + 1, To);
days_for_years(From, To) when From > To ->
    -(days_in_year(To) + days_for_years(To + 1, From)).

days_for_months(To, To, _Year) ->
    0;
days_for_months(From, To, Year) ->
    days_in_month(From, Year) + days_for_months(From + 1, To, Year).

days_in_year(Year) ->
    case is_leap(Year) of
        true  -> 366;
        false -> 365
    end.

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

%% високосный:
%%   делится на 400           -> высокосный
%%   делится на 100 (но не 400) -> не высокосный
%%   делится на 4 (но не 100)  -> высокосный
%%   иначе                    -> не высокосный
is_leap(Year) when Year rem 400 =:= 0 -> true;
is_leap(Year) when Year rem 100 =:= 0 -> false;
is_leap(Year) when Year rem 4   =:= 0 -> true;
is_leap(_Year)                         -> false.
