defmodule FLHook.CommandString do
  defstruct [:name]

  defimpl FLHook.Command do
    def to_cmd(cmd) do
      cmd.name
    end
  end
end
