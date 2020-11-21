defmodule FLHook.Client.ReplyTest do
  use ExUnit.Case

  alias FLHook.Client.Reply
  alias FLHook.Result

  describe "lines/1" do
    assert Reply.lines(%Reply{lines: ["baz", "bar", "", "foo"]}) == [
             "foo",
             "",
             "bar",
             "baz"
           ]
  end

  describe "add_chunk/2" do
    test "OK reply" do
      reply =
        %Reply{}
        |> Reply.add_chunk("foo\r\n\r\nba")
        |> Reply.add_chunk("r\r")
        |> Reply.add_chunk("\nbaz\r\nOK\r\n")

      assert reply.status == :ok
      assert reply.lines == ["baz", "bar", "", "foo"]
    end

    test "ERR reply" do
      reply =
        %Reply{}
        |> Reply.add_chunk("foo\r\n\r\nba")
        |> Reply.add_chunk("r\r")
        |> Reply.add_chunk("\nbaz\r\nERR something went wrong\r\n")

      assert reply.status == {:error, "something went wrong"}
      assert reply.lines == ["baz", "bar", "", "foo"]
    end

    test "pending reply" do
      reply =
        %Reply{}
        |> Reply.add_chunk("foo\r\n\r\nba")
        |> Reply.add_chunk("r\r")
        |> Reply.add_chunk("\nbaz\r\n")

      assert reply.status == :pending
      assert reply.lines == ["", "baz", "bar", "", "foo"]
    end
  end

  describe "to_result/1" do
    test "return result when status is ok" do
      assert Reply.to_result(%Reply{
               status: :ok,
               lines: ["baz", "bar", "", "foo"]
             }) == %Result{lines: ["foo", "", "bar", "baz"]}
    end

    test "raise when status is not ok" do
      assert_raise FunctionClauseError, fn ->
        assert Reply.to_result(%Reply{
                 status: {:error, "something went wrong"},
                 lines: []
               })
      end

      assert_raise FunctionClauseError, fn ->
        assert Reply.to_result(%Reply{
                 status: :pending,
                 lines: []
               })
      end
    end
  end
end
