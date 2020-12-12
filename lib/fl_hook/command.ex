defprotocol FLHook.Command do
  @moduledoc """
  A protocol to implement custom commands.
  """

  @type serializable ::
          String.t()
          | [String.Chars.t()]
          | {String.t(), [String.Chars.t()]}

  @doc """
  Returns a command string or tuple. It may even return another command except
  itself.
  """
  @spec to_cmd(t) :: serializable
  def to_cmd(cmd)
end
