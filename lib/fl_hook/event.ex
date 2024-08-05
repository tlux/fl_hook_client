defmodule FLHook.Event do
  @moduledoc """
  An event that is sent by the client in event mode when something happens on
  the server.
  """

  @event_types [
    "baseenter",
    "baseexit",
    "chat",
    "connect",
    "disconnect",
    "jumpin",
    "kill",
    "launch",
    "login",
    "spawn",
    "switchout"
  ]

  @enforce_keys [:type]
  defstruct [:type, data: %{}]

  @type event_type :: String.t()

  @type t :: %__MODULE__{
          type: event_type,
          data: map
        }

  @doc false
  @spec __event_types__() :: [event_type]
  def __event_types__, do: @event_types

  @doc false
  @spec parse(binary) :: {:ok, t} | :error
  def parse(""), do: :error

  def parse(payload) when is_binary(payload) do
    case String.split(payload, " ", parts: 2) do
      [type, binary] when type in @event_types ->
        {:ok,
         %__MODULE__{
           type: type,
           data: FLHook.Dict.parse(binary, spread: "text")
         }}

      _ ->
        :error
    end
  end
end
