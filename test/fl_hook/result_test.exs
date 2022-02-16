defmodule FLHook.ResultTest do
  use ExUnit.Case, async: true

  alias FLHook.Params
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
    test "decodes params from all lines" do
      assert Result.params_list(@params_result) == [
               Params.new(%{
                 "foo" => "bar",
                 "bar" => "baz",
                 "baz" => "boo"
               }),
               Params.new(%{"bar" => "baz"}),
               Params.new(%{"lorem" => "ipsum"})
             ]
    end
  end

  describe "params/1" do
    test "decodes params from first line" do
      assert Result.params(@params_result) ==
               Params.new(%{
                 "foo" => "bar",
                 "bar" => "baz",
                 "baz" => "boo"
               })
    end

    test "gets empty map when result has no lines" do
      assert Result.params(%{@params_result | lines: []}) == Params.new(%{})
    end
  end

  describe "file_stream!/1" do
    test "decodes the lines as file contents" do
      result = %Result{
        lines: ["l line 1", "l line 2", "l ", "l line 3"]
      }

      assert result |> Result.file_stream!() |> Enum.to_list() ==
               ["line 1", "line 2", "", "line 3"]
    end

    test "raises argument error when result is not a file" do
      assert_raise ArgumentError, "result is not a file", fn ->
        @params_result
        |> Result.file_stream!()
        |> Stream.run()
      end
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
