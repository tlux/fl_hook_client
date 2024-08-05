defmodule FLHook.Coercer do
  @moduledoc """
  Coercer helper for data types returned by the FLHook socket.
  """
  @moduledoc since: "3.0.0"

  @type type ::
          :any | :boolean | :duration | :integer | :float | :string | module

  @true_values ["1", "yes", "enabled"]

  @doc """
  Coerces a value into the given type.
  """
  @spec coerce(any, type) :: {:ok, any} | :error
  def coerce(value, type)

  def coerce(value, :any), do: {:ok, value}

  def coerce(value, :boolean) do
    {:ok, value in @true_values}
  end

  def coerce(value, :duration) do
    coerce(value, FLHook.Duration)
  end

  def coerce(value, :float) do
    case Float.parse(value) do
      {value, ""} -> {:ok, value}
      _ -> :error
    end
  end

  def coerce(value, :integer) do
    case Integer.parse(value) do
      {value, ""} -> {:ok, value}
      _ -> :error
    end
  end

  def coerce(value, :string), do: {:ok, to_string(value)}

  def coerce(value, mod) when is_atom(mod) do
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

  @doc """
  Coerce a value to the given type or raise an error.
  """
  @spec coerce!(any, type) :: any
  def coerce!(value, type) do
    case coerce(value, type) do
      {:ok, value} ->
        value

      :error ->
        raise ArgumentError,
              "invalid value #{inspect(value)} for type #{inspect(type)}"
    end
  end
end
