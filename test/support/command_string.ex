defmodule FLHook.CommandString do
  defstruct [:cmd]

  defimpl FLHook.Command do
    def to_cmd(dispatchable) do
      dispatchable.cmd
    end
  end
end
