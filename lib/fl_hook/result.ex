defmodule FLHook.Result do
  alias FLHook.Utils

  defstruct lines: []

  @type t :: %__MODULE__{lines: [String.t()]}

  @spec to_string(t) :: String.t()
  def to_string(%__MODULE__{} = result) do
    Enum.join(result.lines, Utils.line_sep())
  end

  defimpl String.Chars do
    defdelegate to_string(result), to: FLHook.Result
  end
end
