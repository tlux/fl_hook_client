defmodule FLHook.ParamType do
  @moduledoc """
  A behaviour that can be implemented by custom param types.
  """

  @callback parse(String.t()) :: {:ok, any} | :error
end
