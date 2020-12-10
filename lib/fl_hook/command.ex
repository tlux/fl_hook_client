defprotocol FLHook.Command do
  @moduledoc """
  A protocol to implement custom commands.
  """

  @doc """
  Returns a command string or tuple. It may even return another command except
  itself.
  """
  @spec to_cmd(t) :: FLHook.command()
  def to_cmd(command)
end
