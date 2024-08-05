defmodule FLHook.DurationTest do
  use ExUnit.Case

  describe "parse/1" do
    test "string" do
      assert FLHook.Duration.parse("0:00:00:00") ==
               {:ok, Duration.new!(day: 0, hour: 0, minute: 0, second: 0)}

      assert FLHook.Duration.parse("1:23:45:56") ==
               {:ok, Duration.new!(day: 1, hour: 23, minute: 45, second: 56)}
    end

    test "error" do
      assert FLHook.Duration.parse("invalid") == :error
      assert FLHook.Duration.parse("0") == :error
      assert FLHook.Duration.parse("0:00:00") == :error
      assert FLHook.Duration.parse("0:24:00:00") == :error
      assert FLHook.Duration.parse("0:00:60:00") == :error
      assert FLHook.Duration.parse("0:00:00:60") == :error
      assert FLHook.Duration.parse("-1:00:00:00") == :error
      assert FLHook.Duration.parse("0:-01:00:00") == :error
      assert FLHook.Duration.parse("0:00:-01:00") == :error
      assert FLHook.Duration.parse("0:00:00:-01") == :error
      assert FLHook.Duration.parse(:invalid) == :error
    end
  end
end
