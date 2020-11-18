defmodule FLHook.Event do
  alias FLHook.Params

  defstruct [:type, params: %{}, payload: nil]

  @type t :: %__MODULE__{
    type: String.t(),
    params: Params.params(), 
    payload: String.t()
  }

  @spec parse(String.t()) :: t
  def parse(payload) do
    [type, raw_params] = String.split(str, " ", parts: 2)
    params = Params.parse(raw_params, spread: "text")
    %Event{type: type, params: params, payload: payload}
  end
end
