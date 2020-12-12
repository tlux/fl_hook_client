defmodule FLHook.CommandSerializerTest do
  use ExUnit.Case, async: true

  alias FLHook.CommandSerializer
  alias FLHook.CommandString
  alias FLHook.CommandTuple

  describe "to_string/1" do
    test "serialize string" do
      assert CommandSerializer.to_string("foo") == "foo"
      assert CommandSerializer.to_string("foo\r\nbar") == "foo\\r\\nbar"
    end

    test "serialize tuple" do
      assert CommandSerializer.to_string({"foo", []}) == "foo"
      assert CommandSerializer.to_string({"foo\r\nbar", []}) == "foo\\r\\nbar"

      assert CommandSerializer.to_string({"foo", ["bar", 1337]}) ==
               "foo bar 1337"

      assert CommandSerializer.to_string({"foo", ["bar\r\nbaz", 1337]}) ==
               "foo bar\\r\\nbaz 1337"
    end

    test "serialize FLHook.Command returning string" do
      assert CommandSerializer.to_string(%CommandString{name: "foo"}) ==
               "foo"

      assert CommandSerializer.to_string(%CommandString{name: "foo\r\nbar"}) ==
               "foo\\r\\nbar"
    end

    test "serialize FLHook.Command returning tuple" do
      assert CommandSerializer.to_string(%CommandTuple{
               name: "foo",
               args: []
             }) ==
               "foo"

      assert CommandSerializer.to_string(%CommandTuple{
               name: "foo\r\nbar",
               args: []
             }) ==
               "foo\\r\\nbar"

      assert CommandSerializer.to_string(%CommandTuple{
               name: "foo",
               args: ["bar", 1337]
             }) == "foo bar 1337"

      assert CommandSerializer.to_string(%CommandTuple{
               name: "foo",
               args: ["bar\r\nbaz", 1337]
             }) == "foo bar\\r\\nbaz 1337"
    end
  end
end
