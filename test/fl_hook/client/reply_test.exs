defmodule FLHook.Client.ReplyTest do
  use ExUnit.Case

  alias FLHook.Client.Reply

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
end
