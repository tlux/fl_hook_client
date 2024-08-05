defmodule FLHook.Dict do
  @moduledoc """
  A module for parsing dictionaries that are returned as result rows.
  """

  alias FLHook.Coercer
  alias FLHook.Utils

  @doc """
  Parses a dictionary string into a map.
  """
  @spec parse(binary | [binary], Keyword.t()) :: map
  def parse(binary_or_list, opts \\ [])

  def parse(list, opts) when is_list(list) do
    Enum.map(list, &parse(&1, opts))
  end

  def parse(binary, opts) when is_binary(binary) do
    str = String.trim_trailing(binary, Utils.line_sep())
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
  Coerces the specified entry in the dict into the given type.
  """
  @spec coerce(map, atom, Coercer.type()) :: map
  def coerce(map, key, type) when is_map_key(map, key) do
    Map.update!(map, key, &Coercer.coerce!(&1, type))
  end
end
