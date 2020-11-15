defmodule FLHook.CommandError do
  defexception [:detail]

  @type t :: %__MODULE__{detail: String.t()}

  @impl true
  def message(error) do
    "Command error: #{error.detail}"
  end
end
