defmodule FLHook.ConfigTest do
  use ExUnit.Case, async: true

  alias FLHook.Config

  describe "new/1" do
    test "defaults" do
      config = Config.new(password: "test")

      assert config.backoff_interval == 1000
      assert config.codec == FLHook.Codecs.UTF16LE
      assert config.connect_timeout == 5000
      assert config.event_mode == false
      assert config.host == "localhost"
      assert config.inet_adapter == :inet
      assert config.password == "test"
      assert config.port == 1920
      assert config.recv_timeout == 5000
      assert config.send_timeout == 5000
      assert config.tcp_adapter == :gen_tcp
    end

    test "custom configuration" do
      config =
        Config.new(
          backoff_interval: 1234,
          codec: :ascii,
          connect_timeout: 2345,
          event_mode: true,
          host: "192.168.178.22",
          inet_adapter: FLHook.MockInetAdapter,
          password: "Test1234",
          port: 1919,
          recv_timeout: 3456,
          send_timeout: 4567,
          tcp_adapter: FLHook.MockTCPAdapter
        )

      assert config.backoff_interval == 1234
      assert config.codec == :ascii
      assert config.connect_timeout == 2345
      assert config.event_mode == true
      assert config.host == "192.168.178.22"
      assert config.inet_adapter == FLHook.MockInetAdapter
      assert config.password == "Test1234"
      assert config.port == 1919
      assert config.recv_timeout == 3456
      assert config.send_timeout == 4567
      assert config.tcp_adapter == FLHook.MockTCPAdapter
    end

    test "raise on unknown option" do
      assert_raise KeyError, ~r/key :foo not found/, fn ->
        Config.new(password: "Test1234", foo: "bar")
      end
    end
  end
end
