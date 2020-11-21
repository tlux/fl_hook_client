defmodule FLHook.CommandErrorTest do
  use ExUnit.Case, async: true

  alias FLHook.CommandError

  describe "message/1" do
    test "get message" do
      assert Exception.message(%CommandError{detail: "Unknown command"}) ==
               "Command error: Unknown command"
    end
  end
end
