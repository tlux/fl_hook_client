defmodule FLHook.Client.ResponseTest do
  use ExUnit.Case

  alias FLHook.Client.Request
  alias FLHook.Client.Response

  @empty_response %Response{request_id: Request.random_id()}

  describe "add_chunk/2" do
    test "OK reply" do
      response =
        @empty_response
        |> Response.add_chunk("foo\r\n\r\nba")
        |> Response.add_chunk("r\r")
        |> Response.add_chunk("\nbaz\r\nOK\r\n")

      assert response.status == :ok
      assert response.rows == ["baz", "bar", "", "foo"]
    end

    test "ERR reply" do
      response =
        @empty_response
        |> Response.add_chunk("foo\r\n\r\nba")
        |> Response.add_chunk("r\r")
        |> Response.add_chunk("\nbaz\r\nERR something went wrong\r\n")

      assert response.status == {:error, "something went wrong"}
      assert response.rows == ["baz", "bar", "", "foo"]
    end

    test "pending reply" do
      response =
        @empty_response
        |> Response.add_chunk("foo\r\n\r\nba")
        |> Response.add_chunk("r\r")
        |> Response.add_chunk("\nbaz\r\n")

      assert response.status == :pending
      assert response.rows == ["", "baz", "bar", "", "foo"]
    end
  end

  describe "rows/1" do
    test "return result when status is ok" do
      assert Response.rows(%Response{
               request_id: Request.random_id(),
               status: :ok,
               rows: ["baz", "bar", "", "foo"]
             }) == ["foo", "", "bar", "baz"]
    end

    test "raise when status is not ok" do
      assert_raise FunctionClauseError, fn ->
        assert Response.rows(%Response{
                 request_id: Request.random_id(),
                 status: {:error, "something went wrong"},
                 rows: []
               })
      end

      assert_raise FunctionClauseError, fn ->
        assert Response.rows(%Response{
                 request_id: Request.random_id(),
                 status: :pending,
                 rows: []
               })
      end
    end
  end
end
