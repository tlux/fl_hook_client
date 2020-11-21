defmodule FLHook.ClientTest do
  use ExUnit.Case

  alias FLHook.Client

  test "connect and send commands" do
    start_supervised!(
      {Client,
       host: "workstation.fritz.box",
       port: 1920,
       event_mode: :unicode,
       password: "admin"}
    )

    Process.sleep(1000)
  end
end
