-module(lab4_task4_app).
-behaviour(application).

%% Callbacks для OTP Application behaviour
-export([start/2, stop/1]).

%% start(Type, Args) — вызывается OTP при старте приложения
%% Запускает корневой супервизор
start(_StartType, _StartArgs) ->
    lab4_task4_sup:start_link().

%% stop(State) — вызывается при остановке приложения
stop(_State) ->
    ok.
