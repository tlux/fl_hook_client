defmodule FLHook.CoercerTest do
  use ExUnit.Case, async: true

  import FLHook.Coercer

  describe "coerce/2" do
    test "boolean" do
      assert coerce("1", :boolean) == {:ok, true}
      assert coerce("enabled", :boolean) == {:ok, true}
      assert coerce("yes", :boolean) == {:ok, true}
      assert coerce("yes", :boolean) == {:ok, true}
      assert coerce("0", :boolean) == {:ok, false}
      assert coerce("no", :boolean) == {:ok, false}
    end

    test "duration" do
      assert coerce("1:23:45:56", :duration) ==
               {:ok, Duration.new!(day: 1, hour: 23, minute: 45, second: 56)}

      assert coerce("1:45:56", :duration) == :error
    end

    test "float" do
      assert coerce("1.2", :float) == {:ok, 1.2}
      assert coerce("1.0", :float) == {:ok, 1.0}
      assert coerce("1", :float) == {:ok, 1.0}
      assert coerce("bar", :float) == :error
    end

    test "integer" do
      assert coerce("2", :integer) == {:ok, 2}
      assert coerce("bar", :integer) == :error
      assert coerce("2.2", :integer) == :error
    end

    test "string" do
      assert coerce("bar", :string) == {:ok, "bar"}
    end

    test "custom type" do
      assert coerce("bar", FLHook.CustomFieldType) == {:ok, "BAR"}
      assert coerce("baz", FLHook.CustomFieldType) == :error

      assert_raise ArgumentError, fn ->
        assert coerce("bar", :invalid_parser)
      end
    end
  end

  describe "coerce!/3" do
    test "valid" do
      assert coerce!("1", :float) == 1.0
    end

    test "invalid" do
      assert_raise ArgumentError, fn ->
        coerce!("bar", :float)
      end
    end
  end
end
