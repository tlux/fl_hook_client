defmodule FLHook.Params do
  @moduledoc """
  A module that provides helpers to decode command response and event params.
  """

  alias FLHook.Utils

  @type key :: atom | String.t()
  @type params :: %{optional(String.t()) => String.t()}

  @doc false
  @spec parse(String.t(), Keyword.t()) :: params
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
  end

  @doc """
  Gets the string at the given key from the params.
  """
  @spec string!(params, key) :: String.t()
  def string!(params, key) when is_atom(key) do
    string!(params, Atom.to_string(key))
  end

  def string!(params, key) when is_binary(key) do
    Map.fetch!(params, key)
  end

  def boolean!(params, key) do
    string!(params, key) in ["1", "enabled"]
  end

  @doc """
  Gets the integer at the given key from the params.
  """
  @spec integer!(params, key) :: integer
  def integer!(params, key) do
    params
    |> string!(key)
    |> String.to_integer()
  end

  @doc """
  Gets the float at the given key from the params.
  """
  @spec float!(params, key) :: float
  def float!(params, key) do
    params
    |> string!(key)
    |> String.to_float()
  end

  @doc """
  Gets the duration at the given key from the params.
  """
  @spec duration!(params, key) :: %{
          days: non_neg_integer,
          hours: non_neg_integer,
          minutes: non_neg_integer,
          seconds: non_neg_integer
        }
  def duration!(params, key) do
    params
    |> string!(key)
    |> String.split(":")
    |> Enum.map(&String.to_integer/1)
    |> case do
      [days, hours, minutes, seconds] ->
        %{days: days, hours: hours, minutes: minutes, seconds: seconds}

      _ ->
        raise ArgumentError, "invalid duration"
    end
  end
end
