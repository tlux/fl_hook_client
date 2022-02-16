defmodule FLHook.Params do
  @moduledoc """
  A module that provides helpers to decode command response and event params.
  """

  alias FLHook.Duration
  alias FLHook.Utils

  defstruct data: %{}

  @type key :: atom | String.t()
  @type data :: %{optional(String.t()) => String.t()}
  @type t :: %__MODULE__{data: data}

  @type param_type ::
          :boolean | :duration | :integer | :float | :string | module

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
  Fetches the param with the specified key from the params collection.
  Optionally allows specification of a type to coerce the param to.
  """
  @spec fetch(t, key, param_type) :: {:ok, any} | :error
  def fetch(params, key, type \\ :string)

  def fetch(%__MODULE__{} = params, key, type) when is_atom(key) do
    fetch(params, Atom.to_string(key), type)
  end

  def fetch(%__MODULE__{} = params, key, :boolean) do
    with {:ok, value} <- fetch(params, key) do
      {:ok, value in ["1", "yes", "enabled"]}
    end
  end

  def fetch(%__MODULE__{} = params, key, :duration) do
    fetch(params, key, Duration)
  end

  def fetch(%__MODULE__{} = params, key, :float) do
    with {:ok, value} <- fetch(params, key),
         {value, ""} <- Float.parse(value) do
      {:ok, value}
    else
      _ -> :error
    end
  end

  def fetch(%__MODULE__{} = params, key, :integer) do
    with {:ok, value} <- fetch(params, key),
         {value, ""} <- Integer.parse(value) do
      {:ok, value}
    else
      _ -> :error
    end
  end

  def fetch(%__MODULE__{data: data}, key, :string) do
    Map.fetch(data, key)
  end

  def fetch(%__MODULE__{} = params, key, type_mod) when is_atom(type_mod) do
    if Code.ensure_loaded?(type_mod) &&
         function_exported?(type_mod, :parse, 1) do
      with {:ok, value} <- fetch(params, key),
           {:ok, value} <- type_mod.parse(value) do
        {:ok, value}
      end
    else
      :error
    end
  end

  @doc """
  Fetches the param with the specified key from the params collection.
  Optionally allows specification of a type to coerce the param to. Raises when
  the param is missing or could not be coerced to the given type.
  """
  @spec fetch!(t, key, param_type) :: any | no_return
  def fetch!(%__MODULE__{} = params, key, type \\ :string) do
    case fetch(params, key, type) do
      {:ok, value} -> value
      :error -> raise ArgumentError, "invalid or missing param (#{key})"
    end
  end

  @doc """
  Fetches a param as boolean from the params collection. Raises when the param
  is missing or could not be coerced.
  """
  @spec boolean!(t, key) :: boolean | no_return
  def boolean!(%__MODULE__{} = params, key) do
    fetch!(params, key, :boolean)
  end

  @doc """
  Fetches a param as duration from the params collection. Raises when the param
  is missing or could not be coerced.
  """
  @spec duration!(t, key) :: Duration.t() | no_return
  def duration!(%__MODULE__{} = params, key) do
    fetch!(params, key, :duration)
  end

  @doc """
  Fetches a param as float from the params collection. Raises when the param is
  missing or could not be coerced.
  """
  @spec float!(t, key) :: float | no_return
  def float!(%__MODULE__{} = params, key) do
    fetch!(params, key, :float)
  end

  @doc """
  Fetches a param as integer from the params collection. Raises when the param
  is missing or could not be coerced.
  """
  @spec integer!(t, key) :: integer | no_return
  def integer!(%__MODULE__{} = params, key) do
    fetch!(params, key, :integer)
  end

  @doc """
  Fetches a param as string from the params collection. Raises when the param is
  missing or could not be coerced.
  """
  @spec string!(t, key) :: String.t() | no_return
  def string!(%__MODULE__{} = params, key) do
    fetch!(params, key, :string)
  end
end
