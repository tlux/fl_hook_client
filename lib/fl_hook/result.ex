defmodule FLHook.Result do
  defstruct lines: []

  @type t :: %__MODULE__{lines: [String.t()]}

  @spec to_string(t) :: String.t()
  def to_string(%__MODULE__{} = result) do
    Enum.join(result.lines, "\r\n")
  end

  defimpl String.Chars do
    defdelegate to_string(result), to: FLHook.Result
  end
end
