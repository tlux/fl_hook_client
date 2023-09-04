defmodule FLHook.FieldType do
  @moduledoc """
  A behaviour that can be implemented by custom field types.
  """

  @callback parse(String.t()) :: {:ok, any} | :error
end
