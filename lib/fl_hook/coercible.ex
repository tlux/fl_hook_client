defmodule FLHook.Coercible do
  @moduledoc """
  A behaviour that can be implemented by custom coercer modules that can be
  passed to `FLHook.Coercer.coerce/2`.
  """
  @moduledoc since: "3.0.0"

  @callback parse(binary) :: {:ok, any} | :error
end
