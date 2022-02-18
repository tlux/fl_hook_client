defmodule FLHook.ParamsTest do
  use ExUnit.Case, async: true

  alias FLHook.Duration
  alias FLHook.ParamError
  alias FLHook.Params

  describe "new/0" do
    test "build empty params" do
      assert Params.new() == %Params{data: %{}}
    end
  end

  describe "new/1" do
    test "build empty params" do
      assert Params.new(%{}) == %Params{data: %{}}
    end

    test "build populated params" do
      data = %{"id" => "123", "name" => "Truelight"}
      assert Params.new(data) == %Params{data: data}
    end
  end

  describe "parse/1" do
    test "parses result" do
      assert Params.parse(
               "id=123 name=Truelight ip=192.168.178.1 text=Hello World\r\n"
             ) ==
               Params.new(%{
                 "id" => "123",
                 "name" => "Truelight",
                 "ip" => "192.168.178.1",
                 "text" => "Hello"
               })

      assert Params.parse("Hello=World\r\n") ==
               Params.new(%{"Hello" => "World"})
    end

    test "empty map when no matches in string" do
      assert Params.parse("Hello World") == Params.new()
      assert Params.parse("Hello= World") == Params.new()
      assert Params.parse("Hello = World") == Params.new()
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
               Params.new(%{
                 "id" => "123",
                 "name" => "Truelight",
                 "text" => "Hello World ignored=param"
               })
    end

    test "empty map when no matches in string" do
      assert Params.parse("Hello World", spread: "text") == Params.new()
    end
  end

  describe "fetch/2" do
    test "delegates to fetch/3 with string type" do
      params = Params.new(%{"foo" => "bar"})

      assert Params.fetch(params, "foo") == Params.fetch(params, "foo", :string)
    end
  end

  describe "fetch/3" do
    test "boolean" do
      assert Params.fetch(Params.new(%{"foo" => "1"}), "foo", :boolean) ==
               {:ok, true}

      assert Params.fetch(Params.new(%{"foo" => "enabled"}), "foo", :boolean) ==
               {:ok, true}

      assert Params.fetch(Params.new(%{"foo" => "yes"}), "foo", :boolean) ==
               {:ok, true}

      assert Params.fetch(Params.new(%{"foo" => "yes"}), :foo, :boolean) ==
               {:ok, true}

      assert Params.fetch(Params.new(%{"foo" => "0"}), "foo", :boolean) ==
               {:ok, false}

      assert Params.fetch(Params.new(%{"foo" => "no"}), "foo", :boolean) ==
               {:ok, false}
    end

    test "duration" do
      assert Params.fetch(
               Params.new(%{"foo" => "1:23:45:56"}),
               "foo",
               :duration
             ) ==
               {:ok, %Duration{days: 1, hours: 23, minutes: 45, seconds: 56}}

      assert Params.fetch(Params.new(%{"foo" => "1:45:56"}), "foo", :duration) ==
               {:error, %ParamError{key: "foo"}}
    end

    test "float" do
      assert Params.fetch(Params.new(%{"foo" => "1.2"}), "foo", :float) ==
               {:ok, 1.2}

      assert Params.fetch(Params.new(%{"foo" => "1.0"}), "foo", :float) ==
               {:ok, 1.0}

      assert Params.fetch(Params.new(%{"foo" => "1"}), "foo", :float) ==
               {:ok, 1.0}

      assert Params.fetch(Params.new(%{"foo" => "bar"}), "foo", :float) ==
               {:error, %ParamError{key: "foo"}}
    end

    test "integer" do
      assert Params.fetch(Params.new(%{"foo" => "2"}), "foo", :integer) ==
               {:ok, 2}

      assert Params.fetch(Params.new(%{"foo" => "bar"}), "foo", :integer) ==
               {:error, %ParamError{key: "foo"}}

      assert Params.fetch(Params.new(%{"foo" => "2.2"}), "foo", :integer) ==
               {:error, %ParamError{key: "foo"}}
    end

    test "string" do
      assert Params.fetch(Params.new(%{"foo" => "bar"}), "foo", :string) ==
               {:ok, "bar"}
    end

    test "custom type" do
      assert Params.fetch(
               Params.new(%{"foo" => "bar"}),
               "foo",
               FLHook.CustomParamType
             ) ==
               {:ok, "BAR"}

      assert Params.fetch(
               Params.new(%{"foo" => "baz"}),
               "foo",
               FLHook.CustomParamType
             ) ==
               {:error, %ParamError{key: "foo"}}

      assert Params.fetch(Params.new(%{"foo" => "bar"}), "foo", :invalid_parser) ==
               {:error, %ParamError{key: "foo"}}
    end

    test "error when param missing" do
      assert Params.fetch(Params.new(%{}), "foo", :string) ==
               {:error, %ParamError{key: "foo"}}
    end
  end

  describe "fetch!/2" do
    test "delegates to fetch!/3 with string type" do
      params = Params.new(%{"foo" => "bar"})

      assert Params.fetch!(params, "foo") ==
               Params.fetch!(params, "foo", :string)
    end
  end

  describe "fetch!/3" do
    test "boolean" do
      assert Params.fetch!(Params.new(%{"foo" => "1"}), "foo", :boolean) == true

      assert Params.fetch!(Params.new(%{"foo" => "enabled"}), "foo", :boolean) ==
               true

      assert Params.fetch!(Params.new(%{"foo" => "yes"}), "foo", :boolean) ==
               true

      assert Params.fetch!(Params.new(%{"foo" => "yes"}), :foo, :boolean) ==
               true

      assert Params.fetch!(Params.new(%{"foo" => "0"}), "foo", :boolean) ==
               false

      assert Params.fetch!(Params.new(%{"foo" => "no"}), "foo", :boolean) ==
               false
    end

    test "duration" do
      assert Params.fetch!(
               Params.new(%{"foo" => "1:23:45:56"}),
               "foo",
               :duration
             ) == %Duration{days: 1, hours: 23, minutes: 45, seconds: 56}

      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.fetch!(Params.new(%{"foo" => "1:45:56"}), "foo", :duration)
      end
    end

    test "float" do
      assert Params.fetch!(Params.new(%{"foo" => "1.2"}), "foo", :float) == 1.2
      assert Params.fetch!(Params.new(%{"foo" => "1.0"}), "foo", :float) == 1.0
      assert Params.fetch!(Params.new(%{"foo" => "1"}), "foo", :float) == 1.0

      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.fetch!(Params.new(%{"foo" => "bar"}), "foo", :float)
      end
    end

    test "integer" do
      assert Params.fetch!(Params.new(%{"foo" => "2"}), "foo", :integer) == 2

      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.fetch!(Params.new(%{"foo" => "bar"}), "foo", :integer) == :error
      end

      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.fetch!(Params.new(%{"foo" => "2.2"}), "foo", :integer) == :error
      end
    end

    test "string" do
      assert Params.fetch!(Params.new(%{"foo" => "bar"}), "foo", :string) ==
               "bar"
    end

    test "custom type" do
      assert Params.fetch!(
               Params.new(%{"foo" => "bar"}),
               "foo",
               FLHook.CustomParamType
             ) == "BAR"

      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.fetch!(
          Params.new(%{"foo" => "baz"}),
          "foo",
          FLHook.CustomParamType
        )
      end

      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.fetch!(Params.new(%{"foo" => "bar"}), "foo", :invalid_parser) ==
          :error
      end
    end

    test "raise when param missing" do
      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.fetch!(Params.new(%{}), "foo", :string)
      end
    end
  end

  describe "pick/2" do
    @valid_params Params.new(%{
                    "foo" => "yes",
                    "bar" => "1",
                    "baz" => "hello",
                    "test" => "whatever"
                  })

    test "by key" do
      assert Params.pick(@valid_params, ["foo"]) == {:ok, %{"foo" => "yes"}}
      assert Params.pick(@valid_params, [:foo]) == {:ok, %{foo: "yes"}}

      assert Params.pick(@valid_params, [:foo, :baz]) ==
               {:ok, %{foo: "yes", baz: "hello"}}
    end

    test "by key and type" do
      assert Params.pick(@valid_params, [{"foo", :string}]) ==
               {:ok, %{"foo" => "yes"}}

      assert Params.pick(@valid_params, [{"foo", :boolean}]) ==
               {:ok, %{"foo" => true}}

      assert Params.pick(@valid_params, [:baz, foo: :boolean]) ==
               {:ok, %{baz: "hello", foo: true}}
    end

    test "error when key not found" do
      error = %ParamError{key: "invalid"}

      assert Params.pick(@valid_params, ~w(foo baz invalid)) ==
               {:error, error}

      assert Params.pick(@valid_params, [:foo, :baz, :invalid]) ==
               {:error, error}
    end
  end

  describe "boolean!/2" do
    test "true" do
      assert Params.boolean!(Params.new(%{"foo" => "1"}), "foo") == true
      assert Params.boolean!(Params.new(%{"foo" => "enabled"}), "foo") == true
      assert Params.boolean!(Params.new(%{"foo" => "yes"}), "foo") == true
      assert Params.boolean!(Params.new(%{"foo" => "yes"}), :foo) == true
    end

    test "false" do
      assert Params.boolean!(Params.new(%{"foo" => "0"}), "foo") == false
      assert Params.boolean!(Params.new(%{"foo" => "no"}), "foo") == false
      assert Params.boolean!(Params.new(%{"foo" => "invalid"}), "foo") == false
    end

    test "param missing" do
      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.boolean!(Params.new(%{}), "foo")
      end
    end
  end

  describe "duration!/2" do
    test "valid" do
      assert Params.duration!(Params.new(%{"foo" => "1:23:45:56"}), "foo") ==
               %Duration{days: 1, hours: 23, minutes: 45, seconds: 56}
    end

    test "invalid" do
      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.duration!(Params.new(%{"foo" => "invalid"}), "foo")
      end
    end

    test "param missing" do
      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.duration!(Params.new(%{}), "foo")
      end
    end
  end

  describe "float!/2" do
    test "valid" do
      assert Params.float!(Params.new(%{"foo" => "1.2"}), "foo") == 1.2
      assert Params.float!(Params.new(%{"foo" => "1.0"}), "foo") == 1.0
      assert Params.float!(Params.new(%{"foo" => "1"}), "foo") == 1.0
    end

    test "invalid" do
      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        assert Params.float!(Params.new(%{"foo" => "invalid"}), "foo") == 1.0
      end
    end

    test "param missing" do
      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.float!(Params.new(%{"foo" => "bar"}), "foo")
      end
    end
  end

  describe "integer!/2" do
    test "valid" do
      assert Params.integer!(Params.new(%{"foo" => "2"}), "foo") == 2
    end

    test "invalid" do
      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.integer!(Params.new(%{"foo" => "bar"}), "foo")
      end
    end

    test "param missing" do
      assert_raise ParamError, "invalid or missing param (foo)", fn ->
        Params.integer!(Params.new(%{"foo" => "2.2)"}), "foo")
      end
    end
  end

  describe "string!/2" do
    test "valid" do
      assert Params.string!(Params.new(%{"foo" => "bar"}), "foo") == "bar"
    end
  end
end
