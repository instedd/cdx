Dynamo.under_test(CdpElixir.Dynamo)
Dynamo.Loader.enable
ExUnit.start

defmodule CdpElixir.TestCase do
  use ExUnit.CaseTemplate

  # Enable code reloading on test cases
  setup do
    Dynamo.Loader.enable
    :ok
  end
end
