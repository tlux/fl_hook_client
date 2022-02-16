defmodule FLHook.ParamError do
  @moduledoc """
  An error indicating an invalid or missing param.
  """

  defexception [:key]

  @type t :: %__MODULE__{key: String.t()}

  @impl true
  def message(error) do
    "invalid or missing param (#{error.key})"
  end
end
