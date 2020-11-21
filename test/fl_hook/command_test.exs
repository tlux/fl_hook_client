defmodule FLHook.CommandTest do
  use ExUnit.Case, async: true

  alias FLHook.Command
  alias FLHook.Test.{DispatchableString, DispatchableTuple}

  describe "to_string/1" do
    test "serialize string" do
      assert Command.to_string("foo") == "foo"
      assert Command.to_string("foo\r\nbar") == "foo\\r\\nbar"
    end

    test "serialize tuple" do
      assert Command.to_string({"foo", []}) == "foo"
      assert Command.to_string({"foo\r\nbar", []}) == "foo\\r\\nbar"

      assert Command.to_string({"foo", ["bar", 1337]}) == "foo bar 1337"

      assert Command.to_string({"foo", ["bar\r\nbaz", 1337]}) ==
               "foo bar\\r\\nbaz 1337"
    end

    test "serialize FLHook.Dispatchable returning string" do
      assert Command.to_string(%DispatchableString{cmd: "foo"}) == "foo"

      assert Command.to_string(%DispatchableString{cmd: "foo\r\nbar"}) ==
               "foo\\r\\nbar"
    end

    test "serialize FLHook.Dispatchable returning tuple" do
      assert Command.to_string(%DispatchableTuple{cmd: "foo", args: []}) ==
               "foo"

      assert Command.to_string(%DispatchableTuple{cmd: "foo\r\nbar", args: []}) ==
               "foo\\r\\nbar"

      assert Command.to_string(%DispatchableTuple{
               cmd: "foo",
               args: ["bar", 1337]
             }) == "foo bar 1337"

      assert Command.to_string(%DispatchableTuple{
               cmd: "foo",
               args: ["bar\r\nbaz", 1337]
             }) == "foo bar\\r\\nbaz 1337"
    end
  end
end
