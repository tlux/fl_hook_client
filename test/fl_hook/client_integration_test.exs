defmodule FLHook.ClientIntegrationTest do
  use ExUnit.Case

  alias FLHook.Client
  alias FLHook.CommandError
  alias FLHook.Dict
  alias FLHook.Result
  alias FLHook.SocketError

  @moduletag :integration

  test "send command" do
    client = start_client!()

    assert {:ok, %Result{} = result} = Client.cmd(client, "serverinfo")

    assert %Dict{data: %{"uptime" => _, "serverload" => _, "npcspawn" => _}} =
             Result.one(result)

    assert {:ok, _} = Client.cmd(client, {"msgu", ["Hello FLHook!"]})
  end

  test "command error" do
    client = start_client!()

    assert {:error, %CommandError{} = error} = Client.cmd(client, "invalid")
    assert Exception.message(error) == "Command error: unknown command"
  end

  test "connection closed" do
    client = start_supervised!({Client, password: "invalid pass"})

    assert Client.cmd(client, "serverinfo") ==
             {:error, %SocketError{reason: :closed}}
  end

  defp start_client! do
    start_supervised!(
      {Client,
       host: System.fetch_env!("FLHOOK_HOST"),
       port: String.to_integer(System.get_env("FLHOOK_PORT", "1920")),
       password: System.fetch_env!("FLHOOK_PASSWORD")}
    )
  end
end
