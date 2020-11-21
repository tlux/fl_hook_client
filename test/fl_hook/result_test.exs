defmodule FLHook.ResultTest do
  use ExUnit.Case, async: true

  alias FLHook.Result

  @result %Result{lines: ["foo", "bar", "baz"]}

  describe "to_string/1" do
    test "joins all result lines" do
      assert Result.to_string(@result) == "foo\r\nbar\r\nbaz"
    end
  end

  describe "Kernel.to_string/1" do
    test "delegates to FLHook.Result" do
      assert Result.to_string(@result) == to_string(@result)
    end
  end
end
