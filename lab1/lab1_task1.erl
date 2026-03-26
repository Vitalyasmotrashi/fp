-module(lab1_task1).
-export([seconds/3]).

seconds(Hours, Minutes, Seconds) ->
    Hours * 3600 + Minutes * 60 + Seconds.
