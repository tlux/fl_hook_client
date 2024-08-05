defmodule FLHook.Client.ReplyTest do
  use ExUnit.Case

  alias FLHook.Client.Reply

  describe "add_chunk/2" do
    test "OK reply" do
      reply =
        %Reply{}
        |> Reply.add_chunk("foo\r\n\r\nba")
        |> Reply.add_chunk("r\r")
        |> Reply.add_chunk("\nbaz\r\nOK\r\n")

      assert reply.status == :ok
      assert reply.rows == ["baz", "bar", "", "foo"]
    end

    test "ERR reply" do
      reply =
        %Reply{}
        |> Reply.add_chunk("foo\r\n\r\nba")
        |> Reply.add_chunk("r\r")
        |> Reply.add_chunk("\nbaz\r\nERR something went wrong\r\n")

      assert reply.status == {:error, "something went wrong"}
      assert reply.rows == ["baz", "bar", "", "foo"]
    end

    test "pending reply" do
      reply =
        %Reply{}
        |> Reply.add_chunk("foo\r\n\r\nba")
        |> Reply.add_chunk("r\r")
        |> Reply.add_chunk("\nbaz\r\n")

      assert reply.status == :pending
      assert reply.rows == ["", "baz", "bar", "", "foo"]
    end
  end

  describe "rows/1" do
    test "return result when status is ok" do
      assert Reply.rows(%Reply{
               status: :ok,
               rows: ["baz", "bar", "", "foo"]
             }) == ["foo", "", "bar", "baz"]
    end

    test "raise when status is not ok" do
      assert_raise FunctionClauseError, fn ->
        assert Reply.rows(%Reply{
                 status: {:error, "something went wrong"},
                 rows: []
               })
      end

      assert_raise FunctionClauseError, fn ->
        assert Reply.rows(%Reply{
                 status: :pending,
                 rows: []
               })
      end
    end
  end
end
