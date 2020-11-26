defmodule FLHook.ParamType do
  @moduledoc """
  A behavior that can be implemented by custom param types.
  """

  @callback parse(String.t()) :: {:ok, any} | :error
end
