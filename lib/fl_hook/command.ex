defprotocol FLHook.Command do
  @moduledoc """
  A protocol to implement custom commands.
  """

  @spec to_cmd(t) :: String.t() | {String.t(), [String.Chars.t()]}
  def to_cmd(command)
end
