defmodule FLHook.ResponseErrorTest do
  use ExUnit.Case, async: true

  alias FLHook.ResponseError

  describe "message/1" do
    test "get message" do
      assert Exception.message(%ResponseError{detail: "unknown command"}) ==
               "unknown command"
    end
  end
end
