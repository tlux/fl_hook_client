defmodule FLHook.ClientIntegrationTest do
  use ExUnit.Case

  alias FLHook.Client
  alias FLHook.CommandError
  alias FLHook.Result
  alias FLHook.SocketError

  @moduletag :integration

  test "send command" do
    client = valid_client()

    assert {:ok, %Result{} = result} = Client.cmd(client, "serverinfo")
    assert %{"uptime" => _} = Result.params(result)

    assert {:ok, _} = Client.cmd(client, {"msgu", ["Hello FLHook!"]})
  end

  test "command error" do
    client = valid_client()

    assert {:error, %CommandError{} = error} = Client.cmd(client, "invalid")
    assert Exception.message(error) == "Command error: Invalid command"
  end

  test "connection closed" do
    client = start_supervised!({Client, password: "invalid pass"})

    assert Client.cmd(client, "serverinfo") ==
             {:error, %SocketError{reason: :closed}}
  end

  defp valid_client do
    start_supervised!(
      {Client,
       host: System.fetch_env!("FLHOOK_HOST"),
       port: String.to_integer(System.get_env("FLHOOK_PORT", "1920")),
       password: System.fetch_env!("FLHOOK_PASSWORD")}
    )
  end
end
