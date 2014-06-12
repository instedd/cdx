-module(list_utils).
-compile(export_all).

find(Condition, Default, [E | Rest]) ->
  case Condition(E) of
    true -> E;
    false -> find(Condition, Default, Rest)
  end;

find(_Cond, Default, []) -> Default.
