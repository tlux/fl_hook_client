defmodule FLHook.TestClientTest do
  use ExUnit.Case, async: true

  alias FLHook.TestClient

  test "child specification" do
    start_supervised!(TestClient)

    assert :sys.get_state(TestClient).mod_state.config ==
             TestClient.__config__()
  end
end
