defmodule FLHook.TestClientTest do
  use ExUnit.Case, async: true

  alias FLHook.TestClient

  test "start supervised" do
    start_supervised!(TestClient)
  end
end
