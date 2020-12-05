defmodule FLHook.ConfigErrorTest do
  use ExUnit.Case, async: true

  alias FLHook.ConfigError

  describe "message/1" do
    test "get message" do
      assert Exception.message(%ConfigError{message: "Something went wrong"}) ==
               "Something went wrong"
    end
  end
end
