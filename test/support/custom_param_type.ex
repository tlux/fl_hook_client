defmodule FLHook.CustomFieldType do
  @behaviour FLHook.FieldType

  def parse("bar"), do: {:ok, "BAR"}
  def parse("baz"), do: :error
end
