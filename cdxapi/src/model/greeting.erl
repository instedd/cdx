-module(greeting, [Id, GreetingText]).
-compile(export_all).

validation_tests() ->
  [{fun() -> length(GreetingText) > 0 end,
    "Greeting must be non-empty!"},
  {fun() -> length(GreetingText) =< 140 end,
    "Greeting must be tweetable"}].

before_create() ->
  ModifiedRecord = set(greeting_text,
    re:replace(GreetingText,
      "masticate", "chew",
      [{return, list}])),
  {ok, ModifiedRecord}.
