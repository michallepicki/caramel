% Source code generated with Caramel.
-module(runner).

-export([main/1]).
-export([run_days/1]).
-export([run_one/1]).

-spec run_one({_, fun(() -> _)}) -> ok.
run_one({N, Day}) ->
  io:format(<<"Running day #~p...">>, [N | []]),
  io:format(<<"~p\n">>, [Day() | []]).

-spec run_days(list({_, fun(() -> _)})) -> ok.
run_days(Days) -> lists:foreach(fun
  (Day) -> run_one(Day)
end, Days).

-spec main(_) -> ok.
main(_) ->
  io:format(<<"==# Advent Of Code 2020! #==\n\n">>, []),
  Days = [{1, fun
  () -> day_1:run()
end} | [{2, fun
  () -> day_2:run()
end} | []]],
  run_days(Days),
  io:format(<<"\n\n">>, []).


