defmodule FLHook.Test.DispatchableString do
  defstruct [:cmd]

  defimpl FLHook.Dispatchable do
    def to_cmd(dispatchable) do
      dispatchable.cmd
    end
  end
end
