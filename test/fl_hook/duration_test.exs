defmodule FLHook.DurationTest do
  use ExUnit.Case

  alias FLHook.Duration

  describe "parse/1" do
    test "ok" do
      assert Duration.parse("0:00:00:00") ==
               {:ok, %Duration{days: 0, hours: 0, minutes: 0, seconds: 0}}

      assert Duration.parse("1:23:45:56") ==
               {:ok, %Duration{days: 1, hours: 23, minutes: 45, seconds: 56}}
    end

    test "error" do
      assert Duration.parse("invalid") == :error
      assert Duration.parse("0") == :error
      assert Duration.parse("0:00:00") == :error
      assert Duration.parse("0:24:00:00") == :error
      assert Duration.parse("0:00:60:00") == :error
      assert Duration.parse("0:00:00:60") == :error
      assert Duration.parse("-1:00:00:00") == :error
      assert Duration.parse("0:-01:00:00") == :error
      assert Duration.parse("0:00:-01:00") == :error
      assert Duration.parse("0:00:00:-01") == :error
    end
  end
end
