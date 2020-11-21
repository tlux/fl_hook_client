defmodule FLHook.ConfigTest do
  use ExUnit.Case, async: true

  alias FLHook.Config

  describe "new/0" do
    test "defaults" do
      assert Config.new() == Config.new([])
    end
  end

  describe "new/1" do
    test "defaults" do
      config = Config.new([])

      assert config.codec == :unicode
      assert config.event_mode == false
      assert config.host == "localhost"
      assert config.password == nil
      assert config.port == 1920
      assert config.subscribers == []
    end

    test "custom configuration" do
      config =
        Config.new(
          codec: :ascii,
          event_mode: true,
          host: "192.168.178.22",
          password: "Test1234",
          port: 1919,
          subscribers: [self()]
        )

      assert config.codec == :ascii
      assert config.event_mode == true
      assert config.host == "192.168.178.22"
      assert config.password == "Test1234"
      assert config.port == 1919
      assert config.subscribers == [self()]
    end

    test "raise on unknown option" do
      assert_raise KeyError, ~r/key :foo not found/, fn ->
        Config.new(password: "Test1234", foo: "bar")
      end
    end
  end
end
