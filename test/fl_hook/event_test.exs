defmodule FLHook.EventTest do
  use ExUnit.Case

  alias FLHook.Event

  describe "parse/1" do
    test "parse event with params" do
      payload = "chat from=Player id=1337 type=console text=Hello World"

      assert Event.parse(payload) == %Event{
               type: "chat",
               params: %{
                 "from" => "Player",
                 "id" => "1337",
                 "type" => "console",
                 "text" => "Hello World"
               },
               payload: payload
             }
    end

    test "parse event without params" do
      payload = "unknown"

      assert Event.parse(payload) == %Event{
               type: "unknown",
               params: %{},
               payload: payload
             }
    end

    test "raise on empty payload" do
      assert_raise ArgumentError, "Unable to parse empty event payload", fn ->
        assert Event.parse("")
      end
    end

    test "raise when payload is no string" do
      assert_raise FunctionClauseError, fn ->
        assert Event.parse(:invalid)
      end
    end
  end
end
