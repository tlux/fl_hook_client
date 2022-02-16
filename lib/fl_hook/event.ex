defmodule FLHook.Event do
  @moduledoc """
  An event that is sent by the client in event mode when something happens on
  the server.
  """

  alias FLHook.Params

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

  defstruct [:type, params: %{}]

  @type t :: %__MODULE__{
          type: String.t(),
          params: Params.t()
        }

  @doc false
  @spec __event_types__() :: [String.t()]
  def __event_types__, do: @event_types

  @doc false
  @spec parse(String.t()) :: {:ok, t} | :error
  def parse(""), do: :error

  def parse(payload) when is_binary(payload) do
    case String.split(payload, " ", parts: 2) do
      [type, raw_params] when type in @event_types ->
        params = Params.parse(raw_params, spread: "text")
        {:ok, %__MODULE__{type: type, params: params}}

      _ ->
        :error
    end
  end

  @doc """
  Fetches the param with the specified key from the params collection.
  Optionally allows specification of a type to coerce the param to.
  """
  @spec param(t, Params.key(), Params.param_type()) :: {:ok, any} | :error
  def param(%__MODULE__{params: params}, key, type \\ :string) do
    Params.fetch(params, key, type)
  end

  @doc """
  Fetches the param with the specified key from the params collection.
  Optionally allows specification of a type to coerce the param to. Raises when
  the param is missing or could not be coerced to the given type.
  """
  @spec param!(t, Params.key(), Params.param_type()) :: any | no_return
  def param!(%__MODULE__{params: params}, key, type \\ :string) do
    Params.fetch!(params, key, type)
  end
end
