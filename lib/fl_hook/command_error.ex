defmodule FLHook.CommandError do
  @moduledoc """
  An error indicating a command returned unsuccessfully.
  """

  @enforce_keys [:detail]
  defexception [:detail]

  @type t :: %__MODULE__{detail: String.t()}

  def message(error) do
    "Command error: #{error.detail}"
  end
end
