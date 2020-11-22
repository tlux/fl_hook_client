defmodule FLHook.ResultTest do
  use ExUnit.Case, async: true

  alias FLHook.Result

  @result %Result{lines: ["foo", "bar", "baz"]}

  @params_result %Result{
    lines: [
      "foo=bar bar=baz baz=boo",
      "bar=baz",
      "lorem=ipsum"
    ]
  }

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

  describe "params_list/1" do
    assert Result.params_list(@params_result) == [
             %{
               "foo" => "bar",
               "bar" => "baz",
               "baz" => "boo"
             },
             %{"bar" => "baz"},
             %{"lorem" => "ipsum"}
           ]
  end

  describe "params/1" do
    test "decodes params from first line" do
      assert Result.params(@params_result) == %{
               "foo" => "bar",
               "bar" => "baz",
               "baz" => "boo"
             }
    end
  end

  describe "file!/1" do
    test "decodes the lines as file contents" do
      assert Result.file!(%Result{
               lines: ["l line 1", "l line 2", "l ", "l line 3"]
             }) == ~s(line 1\r\nline 2\r\n\r\nline 3)
    end

    test "raises argument error when result is not a file" do
      assert_raise ArgumentError, "result is not a file", fn ->
        Result.file!(@params_result)
      end
    end
  end
end
