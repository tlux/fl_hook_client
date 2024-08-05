defmodule FLHook.CustomFieldType do
  @behaviour FLHook.Coercible

  def parse("bar"), do: {:ok, "BAR"}
  def parse("baz"), do: :error
end
