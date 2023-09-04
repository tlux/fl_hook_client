defmodule FLHook.DictTest do
  use ExUnit.Case, async: true

  alias FLHook.Dict
  alias FLHook.Duration
  alias FLHook.FieldError
  alias FLHook.TestParamsStruct

  @valid_dict Dict.new(%{
                "foo" => "yes",
                "bar" => "1",
                "baz" => "hello",
                "test" => "whatever"
              })

  describe "new/0" do
    test "build empty dict" do
      assert Dict.new() == %Dict{data: %{}}
    end
  end

  describe "new/1" do
    test "build empty dict" do
      assert Dict.new(%{}) == %Dict{data: %{}}
    end

    test "build populated dict" do
      data = %{"id" => "123", "name" => "Truelight"}
      assert Dict.new(data) == %Dict{data: data}
    end
  end

  describe "parse/1" do
    test "parses result" do
      assert Dict.parse(
               "id=123 name=Truelight ip=192.168.178.1 text=Hello World\r\n"
             ) ==
               Dict.new(%{
                 "id" => "123",
                 "name" => "Truelight",
                 "ip" => "192.168.178.1",
                 "text" => "Hello"
               })

      assert Dict.parse("Hello=World\r\n") ==
               Dict.new(%{"Hello" => "World"})
    end

    test "empty map when no matches in string" do
      assert Dict.parse("Hello World") == Dict.new()
      assert Dict.parse("Hello= World") == Dict.new()
      assert Dict.parse("Hello = World") == Dict.new()
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
             ) ==
               Dict.new(%{
                 "id" => "123",
                 "name" => "Truelight",
                 "text" => "Hello World ignored=param"
               })
    end

    test "empty map when no matches in string" do
      assert Dict.parse("Hello World", spread: "text") == Dict.new()
    end
  end

  describe "fetch/2" do
    test "delegates to fetch/3 with string type" do
      dict = Dict.new(%{"foo" => "bar"})

      assert Dict.fetch(dict, "foo") == Dict.fetch(dict, "foo", :string)
    end
  end

  describe "fetch/3" do
    test "boolean" do
      assert Dict.fetch(Dict.new(%{"foo" => "1"}), "foo", :boolean) ==
               {:ok, true}

      assert Dict.fetch(Dict.new(%{"foo" => "enabled"}), "foo", :boolean) ==
               {:ok, true}

      assert Dict.fetch(Dict.new(%{"foo" => "yes"}), "foo", :boolean) ==
               {:ok, true}

      assert Dict.fetch(Dict.new(%{"foo" => "yes"}), :foo, :boolean) ==
               {:ok, true}

      assert Dict.fetch(Dict.new(%{"foo" => "0"}), "foo", :boolean) ==
               {:ok, false}

      assert Dict.fetch(Dict.new(%{"foo" => "no"}), "foo", :boolean) ==
               {:ok, false}
    end

    test "duration" do
      assert Dict.fetch(
               Dict.new(%{"foo" => "1:23:45:56"}),
               "foo",
               :duration
             ) ==
               {:ok, %Duration{days: 1, hours: 23, minutes: 45, seconds: 56}}

      assert Dict.fetch(Dict.new(%{"foo" => "1:45:56"}), "foo", :duration) ==
               {:error, %FieldError{key: "foo"}}
    end

    test "float" do
      assert Dict.fetch(Dict.new(%{"foo" => "1.2"}), "foo", :float) ==
               {:ok, 1.2}

      assert Dict.fetch(Dict.new(%{"foo" => "1.0"}), "foo", :float) ==
               {:ok, 1.0}

      assert Dict.fetch(Dict.new(%{"foo" => "1"}), "foo", :float) ==
               {:ok, 1.0}

      assert Dict.fetch(Dict.new(%{"foo" => "bar"}), "foo", :float) ==
               {:error, %FieldError{key: "foo"}}
    end

    test "integer" do
      assert Dict.fetch(Dict.new(%{"foo" => "2"}), "foo", :integer) ==
               {:ok, 2}

      assert Dict.fetch(Dict.new(%{"foo" => "bar"}), "foo", :integer) ==
               {:error, %FieldError{key: "foo"}}

      assert Dict.fetch(Dict.new(%{"foo" => "2.2"}), "foo", :integer) ==
               {:error, %FieldError{key: "foo"}}
    end

    test "string" do
      assert Dict.fetch(Dict.new(%{"foo" => "bar"}), "foo", :string) ==
               {:ok, "bar"}
    end

    test "custom type" do
      assert Dict.fetch(
               Dict.new(%{"foo" => "bar"}),
               "foo",
               FLHook.CustomFieldType
             ) ==
               {:ok, "BAR"}

      assert Dict.fetch(
               Dict.new(%{"foo" => "baz"}),
               "foo",
               FLHook.CustomFieldType
             ) ==
               {:error, %FieldError{key: "foo"}}

      assert Dict.fetch(Dict.new(%{"foo" => "bar"}), "foo", :invalid_parser) ==
               {:error, %FieldError{key: "foo"}}
    end

    test "error when param missing" do
      assert Dict.fetch(Dict.new(%{}), "foo", :string) ==
               {:error, %FieldError{key: "foo"}}
    end
  end

  describe "fetch!/2" do
    test "delegates to fetch!/3 with string type" do
      dict = Dict.new(%{"foo" => "bar"})

      assert Dict.fetch!(dict, "foo") ==
               Dict.fetch!(dict, "foo", :string)
    end
  end

  describe "fetch!/3" do
    test "boolean" do
      assert Dict.fetch!(Dict.new(%{"foo" => "1"}), "foo", :boolean) == true

      assert Dict.fetch!(Dict.new(%{"foo" => "enabled"}), "foo", :boolean) ==
               true

      assert Dict.fetch!(Dict.new(%{"foo" => "yes"}), "foo", :boolean) ==
               true

      assert Dict.fetch!(Dict.new(%{"foo" => "yes"}), :foo, :boolean) ==
               true

      assert Dict.fetch!(Dict.new(%{"foo" => "0"}), "foo", :boolean) ==
               false

      assert Dict.fetch!(Dict.new(%{"foo" => "no"}), "foo", :boolean) ==
               false
    end

    test "duration" do
      assert Dict.fetch!(
               Dict.new(%{"foo" => "1:23:45:56"}),
               "foo",
               :duration
             ) == %Duration{days: 1, hours: 23, minutes: 45, seconds: 56}

      assert_raise FieldError, "invalid or missing field (foo)", fn ->
        Dict.fetch!(Dict.new(%{"foo" => "1:45:56"}), "foo", :duration)
      end
    end

    test "float" do
      assert Dict.fetch!(Dict.new(%{"foo" => "1.2"}), "foo", :float) == 1.2
      assert Dict.fetch!(Dict.new(%{"foo" => "1.0"}), "foo", :float) == 1.0
      assert Dict.fetch!(Dict.new(%{"foo" => "1"}), "foo", :float) == 1.0

      assert_raise FieldError, "invalid or missing field (foo)", fn ->
        Dict.fetch!(Dict.new(%{"foo" => "bar"}), "foo", :float)
      end
    end

    test "integer" do
      assert Dict.fetch!(Dict.new(%{"foo" => "2"}), "foo", :integer) == 2

      assert_raise FieldError, "invalid or missing field (foo)", fn ->
        Dict.fetch!(Dict.new(%{"foo" => "bar"}), "foo", :integer) == :error
      end

      assert_raise FieldError, "invalid or missing field (foo)", fn ->
        Dict.fetch!(Dict.new(%{"foo" => "2.2"}), "foo", :integer) == :error
      end
    end

    test "string" do
      assert Dict.fetch!(Dict.new(%{"foo" => "bar"}), "foo", :string) ==
               "bar"
    end

    test "custom type" do
      assert Dict.fetch!(
               Dict.new(%{"foo" => "bar"}),
               "foo",
               FLHook.CustomFieldType
             ) == "BAR"

      assert_raise FieldError, "invalid or missing field (foo)", fn ->
        Dict.fetch!(
          Dict.new(%{"foo" => "baz"}),
          "foo",
          FLHook.CustomFieldType
        )
      end

      assert_raise FieldError, "invalid or missing field (foo)", fn ->
        Dict.fetch!(Dict.new(%{"foo" => "bar"}), "foo", :invalid_parser) ==
          :error
      end
    end

    test "raise when param missing" do
      assert_raise FieldError, "invalid or missing field (foo)", fn ->
        Dict.fetch!(Dict.new(%{}), "foo", :string)
      end
    end
  end

  describe "get/2" do
    test "found" do
      dict = Dict.new(%{"foo" => "bar"})

      assert Dict.get(dict, "foo") == "bar"
    end

    test "not found" do
      dict = Dict.new()

      assert Dict.get(dict, "foo") == nil
    end
  end

  describe "get/3" do
    test "found and type valid" do
      dict = Dict.new(%{"foo" => "1234"})

      assert Dict.get(dict, "foo", :integer) == 1234
    end

    test "found and type invalid" do
      dict = Dict.new(%{"foo" => "1234"})

      assert Dict.get(dict, "foo", :duration) == nil
    end

    test "not found" do
      dict = Dict.new()

      assert Dict.get(dict, "foo", :integer) == nil
    end
  end

  describe "get/4" do
    test "found and type valid" do
      dict = Dict.new(%{"foo" => "1234"})

      assert Dict.get(dict, "foo", :integer, "bar") == 1234
    end

    test "found and type invalid" do
      dict = Dict.new(%{"foo" => "1234"})

      assert Dict.get(dict, "foo", :duration, "bar") == "bar"
    end

    test "not found" do
      dict = Dict.new()

      assert Dict.get(dict, "foo", :integer, "bar") == "bar"
    end
  end

  describe "pick/2" do
    test "by key" do
      assert Dict.pick(@valid_dict, ["foo"]) == {:ok, %{"foo" => "yes"}}
      assert Dict.pick(@valid_dict, [:foo]) == {:ok, %{foo: "yes"}}

      assert Dict.pick(@valid_dict, [:foo, :baz]) ==
               {:ok, %{foo: "yes", baz: "hello"}}
    end

    test "by key and type" do
      assert Dict.pick(@valid_dict, [{"foo", :string}]) ==
               {:ok, %{"foo" => "yes"}}

      assert Dict.pick(@valid_dict, [{"foo", :boolean}]) ==
               {:ok, %{"foo" => true}}

      assert Dict.pick(@valid_dict, [:baz, foo: :boolean]) ==
               {:ok, %{baz: "hello", foo: true}}
    end

    test "error when key not found" do
      error = %FieldError{key: "invalid"}

      assert Dict.pick(@valid_dict, ~w(foo baz invalid)) ==
               {:error, error}

      assert Dict.pick(@valid_dict, [:foo, :baz, :invalid]) ==
               {:error, error}
    end
  end

  describe "pick_into/3" do
    test "by key" do
      assert Dict.pick_into(@valid_dict, TestParamsStruct, [:foo, :baz]) ==
               {:ok, %TestParamsStruct{foo: "yes", baz: "hello"}}
    end

    test "by key and type" do
      assert Dict.pick_into(@valid_dict, TestParamsStruct, [
               :baz,
               foo: :boolean
             ]) == {:ok, %TestParamsStruct{baz: "hello", foo: true}}
    end

    test "error when key not found" do
      error = %FieldError{key: "invalid"}

      assert Dict.pick_into(
               @valid_dict,
               TestParamsStruct,
               ~w(foo baz invalid)
             ) == {:error, error}

      assert Dict.pick_into(@valid_dict, TestParamsStruct, [
               :foo,
               :baz,
               :invalid
             ]) == {:error, error}
    end
  end

  describe "to_map/1" do
    test "convert to map" do
      assert Dict.to_map(@valid_dict) ==
               Dict.to_map(@valid_dict, :string)
    end
  end

  describe "to_map/2" do
    test "string key style" do
      assert Dict.to_map(@valid_dict, :string) == @valid_dict.data
    end

    test "atom key style" do
      assert Dict.to_map(@valid_dict, :atom) == %{
               bar: "1",
               baz: "hello",
               foo: "yes",
               test: "whatever"
             }
    end
  end
end
