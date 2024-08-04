defmodule FLHook.Coercible do
  @moduledoc """
  A behaviour that can be implemented by custom coercer modules.
  """
  @moduledoc since: "2.2.0"

  @callback parse(String.t()) :: {:ok, any} | :error
end

# Remove this with version 3.0.0
defmodule FLHook.FieldType do
  @moduledoc """
  A behaviour that can be implemented by custom coercer modules.
  """
  @moduledoc deprecated: "Use the `FLHook.Coercible` behaviour instead"

  @callback parse(String.t()) :: {:ok, any} | :error
end
