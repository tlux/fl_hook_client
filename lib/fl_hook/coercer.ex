defmodule FLHook.Coercer do
  @moduledoc """
  Coercer for data types returned by the FLHook socket.
  """
  @moduledoc since: "2.2.0"

  @type type ::
          :any | :boolean | :duration | :integer | :float | :string | module

  @true_values ["1", "yes", "enabled"]

  @spec coerce(type, any) :: {:ok, any} | :error
  def coerce(type, value)

  def coerce(:any, value), do: {:ok, value}

  def coerce(:boolean, value) do
    {:ok, value in @true_values}
  end

  def coerce(:duration, value) do
    coerce(FLHook.Duration, value)
  end

  def coerce(:float, value) do
    case Float.parse(value) do
      {value, ""} -> {:ok, value}
      _ -> :error
    end
  end

  def coerce(:integer, value) do
    case Integer.parse(value) do
      {value, ""} -> {:ok, value}
      _ -> :error
    end
  end

  def coerce(:string, value), do: {:ok, to_string(value)}

  def coerce(mod, value) when is_atom(mod) do
    if Code.ensure_loaded?(mod) &&
         function_exported?(mod, :parse, 1) do
      mod.parse(value)
    else
      raise ArgumentError,
            "module #{inspect(mod)} is not loaded or " <>
              "does not implement parse/1"
    end
  end

  def coerce(_, _), do: :error
end
