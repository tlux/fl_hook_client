defmodule FLHook.DictTest do
  use ExUnit.Case, async: true

  alias FLHook.Dict

  describe "parse/1" do
    test "parses result" do
      assert Dict.parse(
               "id=123 name=Truelight ip=192.168.178.1 text=Hello World\r\n"
             ) == %{
               "id" => "123",
               "name" => "Truelight",
               "ip" => "192.168.178.1",
               "text" => "Hello"
             }

      assert Dict.parse("Hello=World\r\n") ==
               %{"Hello" => "World"}
    end

    test "empty map when no matches in string" do
      assert Dict.parse("Hello World") == %{}
      assert Dict.parse("Hello= World") == %{}
      assert Dict.parse("Hello = World") == %{}
    end

    test "raise when arg is no string" do
      assert_raise FunctionClauseError, fn ->
        Dict.parse(:invalid)
      end
    end
  end

  describe "parse/2" do
    test "parses result" do
      assert Dict.parse(
               ~s(id=123 name=Truelight text=Hello World ignored=param\r\n),
               spread: "text"
             ) == %{
               "id" => "123",
               "name" => "Truelight",
               "text" => "Hello World ignored=param"
             }
    end

    test "empty map when no matches in string" do
      assert Dict.parse("Hello World", spread: "text") == %{}
    end
  end
end
