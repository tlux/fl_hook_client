defprotocol FLHook.Dispatchable do
  @moduledoc """
  A protocol to implement custom commands.
  """

  @spec to_cmd(t) :: String.t() | {String.t(), [String.Chars.t()]}
  def to_cmd(dispatchable)
end
