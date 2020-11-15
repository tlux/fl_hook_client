defmodule FLHook.CommandError do
  defexception [:reason]

  @type t :: %__MODULE__{reason: String.t()}

  @impl true
  def message(error) do
    "Command error: #{error.reason}"
  end
end
