defmodule FLHook.ParamsTest do
  use ExUnit.Case, async: true

  alias FLHook.Params

  describe "parse/1" do
    test "parses result" do
      assert Params.parse(
               "id=123 name=Truelight ip=192.168.178.1 text=Hello World\r\n"
             ) ==
               %{
                 "id" => "123",
                 "name" => "Truelight",
                 "ip" => "192.168.178.1",
                 "text" => "Hello"
               }

      assert Params.parse("Hello=World\r\n") == %{"Hello" => "World"}
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
               ~s(id=123 name=Truelight text=Hello World ignored=param\r\n),
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

  describe "fetch/2" do
    test "delegates to fetch/3 with string type" do
      params = %{"foo" => "bar"}

      assert Params.fetch(params, "foo") == Params.fetch(params, "foo", :string)
    end
  end

  describe "fetch/3" do
    test "boolean" do
      assert Params.fetch(%{"foo" => "1"}, "foo", :boolean) == {:ok, true}
      assert Params.fetch(%{"foo" => "enabled"}, "foo", :boolean) == {:ok, true}
      assert Params.fetch(%{"foo" => "yes"}, "foo", :boolean) == {:ok, true}
      assert Params.fetch(%{"foo" => "yes"}, :foo, :boolean) == {:ok, true}
      assert Params.fetch(%{"foo" => "0"}, "foo", :boolean) == {:ok, false}
      assert Params.fetch(%{"foo" => "no"}, "foo", :boolean) == {:ok, false}
    end

    test "duration" do
      assert Params.fetch(%{"foo" => "1:23:45:56"}, "foo", :duration) ==
               {:ok, %{days: 1, hours: 23, minutes: 45, seconds: 56}}

      assert Params.fetch(%{"foo" => "1:45:56"}, "foo", :duration) == :error
    end

    test "float" do
      assert Params.fetch(%{"foo" => "1.2"}, "foo", :float) == {:ok, 1.2}
      assert Params.fetch(%{"foo" => "1.0"}, "foo", :float) == {:ok, 1.0}
      assert Params.fetch(%{"foo" => "1"}, "foo", :float) == {:ok, 1.0}
      assert Params.fetch(%{"foo" => "bar"}, "foo", :float) == :error
    end

    test "integer" do
      assert Params.fetch(%{"foo" => "2"}, "foo", :integer) == {:ok, 2}
      assert Params.fetch(%{"foo" => "bar"}, "foo", :integer) == :error
      assert Params.fetch(%{"foo" => "2.2"}, "foo", :integer) == :error
    end

    test "string" do
      assert Params.fetch(%{"foo" => "bar"}, "foo", :string) == {:ok, "bar"}
    end

    test "error when param missing" do
      assert Params.fetch(%{}, "foo", :string) == :error
    end
  end

  describe "fetch!/2" do
    test "delegates to fetch!/3 with string type" do
      params = %{"foo" => "bar"}

      assert Params.fetch!(params, "foo") ==
               Params.fetch!(params, "foo", :string)
    end
  end

  describe "fetch!/3" do
    test "boolean" do
      assert Params.fetch!(%{"foo" => "1"}, "foo", :boolean) == true
      assert Params.fetch!(%{"foo" => "enabled"}, "foo", :boolean) == true
      assert Params.fetch!(%{"foo" => "yes"}, "foo", :boolean) == true
      assert Params.fetch!(%{"foo" => "yes"}, :foo, :boolean) == true
      assert Params.fetch!(%{"foo" => "0"}, "foo", :boolean) == false
      assert Params.fetch!(%{"foo" => "no"}, "foo", :boolean) == false
    end

    test "duration" do
      assert Params.fetch!(%{"foo" => "1:23:45:56"}, "foo", :duration) ==
               %{days: 1, hours: 23, minutes: 45, seconds: 56}

      assert_raise ArgumentError, "invalid or missing param (foo)", fn ->
        Params.fetch!(%{"foo" => "1:45:56"}, "foo", :duration)
      end
    end

    test "float" do
      assert Params.fetch!(%{"foo" => "1.2"}, "foo", :float) == 1.2
      assert Params.fetch!(%{"foo" => "1.0"}, "foo", :float) == 1.0
      assert Params.fetch!(%{"foo" => "1"}, "foo", :float) == 1.0

      assert_raise ArgumentError, "invalid or missing param (foo)", fn ->
        Params.fetch!(%{"foo" => "bar"}, "foo", :float)
      end
    end

    test "integer" do
      assert Params.fetch!(%{"foo" => "2"}, "foo", :integer) == 2

      assert_raise ArgumentError, "invalid or missing param (foo)", fn ->
        Params.fetch!(%{"foo" => "bar"}, "foo", :integer) == :error
      end

      assert_raise ArgumentError, "invalid or missing param (foo)", fn ->
        Params.fetch!(%{"foo" => "2.2"}, "foo", :integer) == :error
      end
    end

    test "string" do
      assert Params.fetch!(%{"foo" => "bar"}, "foo", :string) == "bar"
    end

    test "raise when param missing" do
      assert_raise ArgumentError, "invalid or missing param (foo)", fn ->
        Params.fetch!(%{}, "foo", :string)
      end
    end
  end
end
