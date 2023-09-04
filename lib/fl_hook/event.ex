defmodule FLHook.Event do
  @moduledoc """
  An event that is sent by the client in event mode when something happens on
  the server.
  """

  alias FLHook.Dict

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

  defstruct [:type, dict: %Dict{}]

  @type t :: %__MODULE__{
          type: String.t(),
          dict: Dict.t()
        }

  @doc false
  @spec __event_types__() :: [String.t()]
  def __event_types__, do: @event_types

  @doc false
  @spec parse(String.t()) :: {:ok, t} | :error
  def parse(""), do: :error

  def parse(payload) when is_binary(payload) do
    case String.split(payload, " ", parts: 2) do
      [type, raw_dict] when type in @event_types ->
        dict = Dict.parse(raw_dict, spread: "text")
        {:ok, %__MODULE__{type: type, dict: dict}}

      _ ->
        :error
    end
  end
end
