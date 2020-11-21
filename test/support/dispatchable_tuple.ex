defmodule FLHook.Test.DispatchableTuple do
  defstruct [:cmd, :args]

  defimpl FLHook.Dispatchable do
    def to_cmd(dispatchable) do
      {dispatchable.cmd, dispatchable.args}
    end
  end
end
