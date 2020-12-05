defmodule FLHook.HandshakeErrorTest do
  use ExUnit.Case, async: true

  alias FLHook.HandshakeError

  describe "message/1" do
    test "get message" do
      assert Exception.message(%HandshakeError{actual_message: "Lorem Ipsum"}) ==
               "Socket is not a valid FLHook socket"
    end
  end
end
