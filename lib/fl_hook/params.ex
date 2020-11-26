defmodule FLHook.Params do
  @moduledoc """
  A module that provides helpers to decode command response and event params.
  """

  alias FLHook.Utils

  @type key :: atom | String.t()
  @type params :: %{optional(String.t()) => String.t()}
  @type param_type :: :boolean | :duration | :integer | :float | :string

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

  @spec fetch(params, key, param_type) :: {:ok, any} | :error
  def fetch(params, key, type \\ :string)

  def fetch(params, key, :boolean) do
    with {:ok, value} <- fetch(params, key) do
      {:ok, value in ["1", "enabled"]}
    end
  end

  def fetch(params, key, :duration) do
    with {:ok, value} <- fetch(params, key),
         [days, hours, minutes, seconds] <- String.split(value, ":", parts: 4),
         {days, ""} <- Integer.parse(days),
         {hours, ""} <- Integer.parse(hours),
         {minutes, ""} <- Integer.parse(minutes),
         {seconds, ""} <- Integer.parse(seconds) do
      {:ok, %{days: days, hours: hours, minutes: minutes, seconds: seconds}}
    else
      _ -> :error
    end
  end

  def fetch(params, key, :float) do
    with {:ok, value} <- fetch(params, key),
         {value, ""} <- Float.parse(value) do
      {:ok, value}
    else
      _ -> :error
    end
  end

  def fetch(params, key, :integer) do
    with {:ok, value} <- fetch(params, key),
         {value, ""} <- Integer.parse(value) do
      {:ok, value}
    else
      _ -> :error
    end
  end

  def fetch(params, key, :string) do
    Map.fetch(params, key)
  end

  @spec fetch!(params, key, param_type) :: any | no_return
  def fetch!(params, key, type \\ :string) do
    case fetch(params, key, type) do
      {:ok, value} -> value
      :error -> raise ArgumentError, "invalid or missing param (#{key})"
    end
  end
end
