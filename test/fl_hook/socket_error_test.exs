defmodule FLHook.SocketErrorTest do
  use ExUnit.Case, async: true

  alias FLHook.SocketError

  describe "message/1" do
    test "closed error" do
      assert Exception.message(%SocketError{reason: :closed}) ==
               "Socket error: connection closed"
    end

    test "econnrefused" do
      assert Exception.message(%SocketError{reason: :econnrefused}) ==
               "Socket error: connection refused"
    end
  end
end
