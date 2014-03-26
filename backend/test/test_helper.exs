Dynamo.under_test(Cdp.Dynamo)
Dynamo.Loader.enable
ExUnit.start

defmodule Cdp.TestCase do
  use ExUnit.CaseTemplate

  # Enable code reloading on test cases
  setup do
    Dynamo.Loader.enable
    :ok
  end
end
