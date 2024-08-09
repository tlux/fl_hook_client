defmodule FLHook.ResponseError do
  @moduledoc """
  An error indicating a response error.
  """

  @enforce_keys [:detail]
  defexception [:detail]

  @type t :: %__MODULE__{detail: String.t()}

  def message(error), do: error.detail
end
