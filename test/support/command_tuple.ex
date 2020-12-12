defmodule FLHook.CommandTuple do
  defstruct [:name, :args]

  defimpl FLHook.Command do
    def to_cmd(cmd) do
      {cmd.name, cmd.args}
    end
  end
end
