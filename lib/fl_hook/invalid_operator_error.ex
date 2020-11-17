defmodule FLHook.InvalidOperationError do
  defexception [:message]

  @type t :: %__MODULE__{message: String.t()}
end
