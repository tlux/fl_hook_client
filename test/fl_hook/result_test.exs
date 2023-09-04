defmodule FLHook.ResultTest do
  use ExUnit.Case, async: true

  alias FLHook.Dict
  alias FLHook.Result

  @result %Result{lines: ["foo", "bar", "baz"]}

  @result_with_data %Result{
    lines: [
      "foo=bar bar=baz baz=1",
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

  describe "all/1" do
    test "decodes data from all lines" do
      assert Result.all(@result_with_data) == [
               Dict.new(%{
                 "foo" => "bar",
                 "bar" => "baz",
                 "baz" => "1"
               }),
               Dict.new(%{"bar" => "baz"}),
               Dict.new(%{"lorem" => "ipsum"})
             ]
    end
  end

  describe "one/1" do
    test "decodes data from first line" do
      assert Result.one(@result_with_data) ==
               Dict.new(%{
                 "foo" => "bar",
                 "bar" => "baz",
                 "baz" => "1"
               })
    end

    test "gets empty map when result has no lines" do
      assert Result.one(%{@result_with_data | lines: []}) == Dict.new(%{})
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
        @result_with_data
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
        Result.file!(@result_with_data)
      end
    end
  end
end
