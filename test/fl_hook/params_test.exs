defmodule FLHook.ParamsTest do
  use ExUnit.Case

  alias FLHook.Params

  describe "parse/1" do
    test "parses result" do
      assert Params.parse(
               ~s(id=123 name=Truelight ip=192.168.178.1 text=Hello World)
             ) ==
               %{
                 "id" => "123",
                 "name" => "Truelight",
                 "ip" => "192.168.178.1",
                 "text" => "Hello"
               }

      assert Params.parse("Hello=World") == %{"Hello" => "World"}
    end

    test "empty map when no matches in string" do
      assert Params.parse("Hello World") == %{}
      assert Params.parse("Hello= World") == %{}
      assert Params.parse("Hello = World") == %{}
    end

    test "raise when arg is no string" do
      assert_raise FunctionClauseError, fn ->
        Params.parse(:invalid)
      end
    end
  end

  describe "parse/2" do
    test "parses result" do
      assert Params.parse(
               ~s(id=123 name=Truelight text=Hello World ignored=param),
               spread: "text"
             ) ==
               %{
                 "id" => "123",
                 "name" => "Truelight",
                 "text" => "Hello World ignored=param"
               }
    end

    test "empty map when no matches in string" do
      assert Params.parse("Hello World", spread: "text") == %{}
    end
  end
end
