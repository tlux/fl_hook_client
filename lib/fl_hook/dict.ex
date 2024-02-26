defmodule FLHook.Dict do
  @moduledoc """
  A module that provides helpers to decode command response and event data.
  """

  alias FLHook.Duration
  alias FLHook.FieldError
  alias FLHook.Utils

  defstruct data: %{}

  @type key :: atom | String.t()
  @type data :: %{optional(String.t()) => String.t()}
  @type t :: %__MODULE__{data: data}

  @type field_type ::
          :any | :boolean | :duration | :integer | :float | :string | module

  @doc false
  @spec new(data) :: t
  def new(data \\ %{}), do: %__MODULE__{data: data}

  @doc false
  @spec parse(String.t(), Keyword.t()) :: t
  def parse(str, opts \\ []) when is_binary(str) do
    str = String.trim_trailing(str, Utils.line_sep())
    str_len = String.length(str)
    spread = opts[:spread]

    ~r/(?<key>\w+)\=(?<value>\S+)/
    |> Regex.scan(str, captures: [:key, :value], return: :index)
    |> Enum.reduce_while(
      %{},
      fn [_, {key_idx, key_len}, {value_idx, value_len}], map ->
        key = String.slice(str, key_idx, key_len)

        if key == spread do
          value = String.slice(str, value_idx, str_len - value_idx)
          {:halt, Map.put(map, key, value)}
        else
          value = String.slice(str, value_idx, value_len)
          {:cont, Map.put(map, key, value)}
        end
      end
    )
    |> new()
  end

  @doc """
  Fetches multiple fields with the specified keys from the dict. Optionally
  allows specification of a type to coerce the param to.
  """
  @doc since: "0.3.0"
  @spec pick(t, [key] | [{key, field_type}]) ::
          {:ok, %{optional(key) => any}} | {:error, FieldError.t()}
  def pick(%__MODULE__{} = dict, keys_and_types)
      when is_list(keys_and_types) do
    Enum.reduce_while(keys_and_types, {:ok, %{}}, fn key_and_type, {:ok, map} ->
      {key, type} = resolve_key_and_type(key_and_type)

      case fetch(dict, key, type) do
        {:ok, value} -> {:cont, {:ok, Map.put(map, key, value)}}
        error -> {:halt, error}
      end
    end)
  end

  defp resolve_key_and_type({key, type}), do: {key, type}
  defp resolve_key_and_type(key), do: {key, :any}

  @doc """
  Puts multiple fields using the specified keys from the dict into the given
  struct. Optionally allows specification of a type to coerce the param to.
  """
  @doc since: "0.3.0"
  @spec pick_into(t, module | struct, [key] | [{key, field_type}]) ::
          {:ok, struct} | {:error, FieldError.t()}
  def pick_into(%__MODULE__{} = dict, target, keys_and_types)
      when is_list(keys_and_types) do
    with {:ok, fields} <- pick(dict, keys_and_types) do
      {:ok, struct(target, fields)}
    end
  end

  @doc """
  Fetches the field using the specified key from the dict. Optionally allows
  specification of a type to coerce the param to.
  """
  @spec fetch(t, key, field_type) :: {:ok, any} | {:error, FieldError.t()}
  def fetch(dict, key, type \\ :any)

  def fetch(%__MODULE__{} = dict, key, type) when is_atom(key) do
    fetch(dict, Atom.to_string(key), type)
  end

  def fetch(%__MODULE__{data: data}, key, :any) do
    with :error <- Map.fetch(data, key) do
      {:error, %FieldError{key: key}}
    end
  end

  def fetch(%__MODULE__{} = dict, key, :boolean) do
    with {:ok, value} <- fetch(dict, key) do
      {:ok, value in ["1", "yes", "enabled"]}
    end
  end

  def fetch(%__MODULE__{} = dict, key, :duration) do
    fetch(dict, key, Duration)
  end

  def fetch(%__MODULE__{} = dict, key, :float) do
    with {:ok, value} <- fetch(dict, key),
         {value, ""} <- Float.parse(value) do
      {:ok, value}
    else
      _ -> {:error, %FieldError{key: key}}
    end
  end

  def fetch(%__MODULE__{} = dict, key, :integer) do
    with {:ok, value} <- fetch(dict, key),
         {value, ""} <- Integer.parse(value) do
      {:ok, value}
    else
      _ -> {:error, %FieldError{key: key}}
    end
  end

  def fetch(%__MODULE__{} = dict, key, :string) do
    with {:ok, value} <- fetch(dict, key) do
      {:ok, to_string(value)}
    end
  end

  def fetch(%__MODULE__{} = dict, key, type_mod) when is_atom(type_mod) do
    if Code.ensure_loaded?(type_mod) &&
         function_exported?(type_mod, :parse, 1) do
      with {:ok, value} <- fetch(dict, key),
           {:ok, value} <- type_mod.parse(value) do
        {:ok, value}
      else
        _ -> {:error, %FieldError{key: key}}
      end
    else
      {:error, %FieldError{key: key}}
    end
  end

  @doc """
  Fetches the field using the specified key from the dict. Optionally allows
  specification of a type to coerce the value to. Raises when the param is
  missing or could not be coerced to the given type.
  """
  @spec fetch!(t, key, field_type) :: any | no_return
  def fetch!(%__MODULE__{} = dict, key, type \\ :any) do
    case fetch(dict, key, type) do
      {:ok, value} -> value
      {:error, error} -> raise error
    end
  end

  @doc """
  Gets the field using the specified key from the dict.
  """
  def get(%__MODULE__{} = dict, key, type \\ :any, default \\ nil) do
    case fetch(dict, key, type) do
      {:ok, value} -> value
      _ -> default
    end
  end

  @doc """
  Converts the dict to a plain map.
  """
  @doc since: "0.3.0"
  @spec to_map(t, key_style :: :string | :atom) ::
          %{optional(atom) => String.t()}
          | %{optional(String.t()) => String.t()}
  def to_map(%__MODULE__{data: data}, key_style \\ :string) do
    Map.new(data, fn {key, value} ->
      {format_map_key(key, key_style), value}
    end)
  end

  defp format_map_key(key, :atom), do: String.to_atom(key)
  defp format_map_key(key, :string), do: key

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(dict, opts) do
      concat(["FLHook.Dict.new(", to_doc(FLHook.Dict.to_map(dict), opts), ")"])
    end
  end
end
