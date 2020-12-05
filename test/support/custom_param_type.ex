defmodule FLHook.CustomParamType do
  @behaviour FLHook.ParamType

  def parse("bar"), do: {:ok, "BAR"}
  def parse("baz"), do: :error
end
