defmodule FLHook.ClientIntegrationTest do
  use ExUnit.Case

  alias FLHook.Client
  alias FLHook.Result

  @moduletag :integration

  test "connect and send command" do
    {:ok, client} =
      start_supervised(
        {Client,
         host: System.fetch_env!("FLHOOK_HOST"),
         port: String.to_integer(System.get_env("FLHOOK_PORT", "1920")),
         password: System.fetch_env!("FLHOOK_PASSWORD")}
      )

    assert {:ok, %Result{} = result} = Client.cmd(client, "serverinfo")
    assert %{"uptime" => _} = Result.params(result)

    assert {:ok, _} = Client.cmd(client, {"msgu", ["Hello FLHook!"]})
  end
end
