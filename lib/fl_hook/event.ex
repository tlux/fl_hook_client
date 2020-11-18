defmodule FLHook.Event do
  @moduledoc """
  An event that is sent by the client in event mode when something happens on
  the server.
  """

  alias FLHook.Params

  defstruct [:type, params: %{}, payload: nil]

  @type t :: %__MODULE__{
          type: String.t(),
          params: Params.params(),
          payload: String.t()
        }

  @spec parse(String.t()) :: t | no_return
  def parse("") do
    raise ArgumentError, "Unable to parse empty event payload"
  end

  def parse(payload) when is_binary(payload) do
    case String.split(payload, " ", parts: 2) do
      [type, raw_params] ->
        params = Params.parse(raw_params, spread: "text")
        %__MODULE__{type: type, params: params, payload: payload}

      [type] ->
        %__MODULE__{type: type, payload: payload}
    end
  end
end
