defmodule FLHook.ClientTest do
  use ExUnit.Case

  alias FLHook.Client

  test "connect and send commands" do
    client =
      Client.start_link(
        host: "workstation.fritz.box",
        port: 1920,
        socket_mode: :unicode,
        password: "admin"
      )

    Process.sleep(1000)
  end
end
