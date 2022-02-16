defmodule FLHook.EventTest do
  use ExUnit.Case, async: true

  alias FLHook.Event
  alias FLHook.Params

  describe "parse/1" do
    test "parse known event with params" do
      event_types = Event.__event_types__()

      assert length(event_types) > 0

      Enum.each(event_types, fn event_type ->
        assert Event.parse(
                 "#{event_type} from=Player id=1337 type=console text=Hello World"
               ) ==
                 {:ok,
                  %Event{
                    type: event_type,
                    params:
                      Params.new(%{
                        "from" => "Player",
                        "id" => "1337",
                        "type" => "console",
                        "text" => "Hello World"
                      })
                  }}
      end)
    end

    test "error when payload has only params" do
      assert Event.parse("from=Player") == :error
    end

    test "error when event has no params" do
      assert Event.parse("chat") == :error
    end

    test "error when event is unknown" do
      assert Event.parse("unknown from=Player") == :error
    end

    test "error on empty payload" do
      assert Event.parse("") == :error
    end
  end

  describe "param/2" do
    test "delegate to Params" do
      params = Params.new(%{"foo" => "bar"})
      event = %Event{params: params}

      assert Event.param(event, "foo") == Params.fetch(params, "foo", :string)
    end
  end

  describe "param/3" do
    test "delegate to Params" do
      params = Params.new(%{"foo" => "1"})
      event = %Event{params: params}

      assert Event.param(event, "foo", :boolean) ==
               Params.fetch(params, "foo", :boolean)
    end
  end

  describe "param!/2" do
    test "delegate to Params" do
      params = Params.new(%{"foo" => "bar"})
      event = %Event{params: params}

      assert Event.param!(event, "foo") == Params.fetch!(params, "foo", :string)
    end
  end

  describe "param!/3" do
    test "delegate to Params" do
      params = Params.new(%{"foo" => "1"})
      event = %Event{params: params}

      assert Event.param!(event, "foo", :boolean) ==
               Params.fetch!(params, "foo", :boolean)
    end
  end
end
