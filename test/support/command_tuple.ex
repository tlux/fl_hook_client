defmodule FLHook.CommandTuple do
  defstruct [:cmd, :args]

  defimpl FLHook.Command do
    def to_cmd(dispatchable) do
      {dispatchable.cmd, dispatchable.args}
    end
  end
end
