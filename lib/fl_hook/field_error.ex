defmodule FLHook.FieldError do
  @moduledoc """
  An error indicating an invalid or missing param.
  """

  defexception [:key]

  @type t :: %__MODULE__{key: String.t()}

  def message(error) do
    "invalid or missing field (#{error.key})"
  end
end
