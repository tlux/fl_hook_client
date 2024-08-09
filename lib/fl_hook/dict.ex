defmodule FLHook.Dict do
  @moduledoc """
  A module for parsing dictionaries that are returned as result rows.
  """

  alias FLHook.Utils

  @doc """
  Parses a dictionary string into a map.

  ## Options

  - `:rest` - A key that defines the last value in the dictionary.
    All key/value pairs following this key will not create new map entries.
  """
  @spec parse(binary, Keyword.t()) :: map
  def parse(binary, opts \\ []) when is_binary(binary) do
    str = String.trim_trailing(binary, Utils.line_sep())
    str_len = String.length(str)
    rest = opts[:rest]

    ~r/(?<key>\w+)\=(?<value>\S+)/
    |> Regex.scan(str, captures: [:key, :value], return: :index)
    |> Enum.reduce_while(
      %{},
      fn [_, {key_idx, key_len}, {value_idx, value_len}], map ->
        key = String.slice(str, key_idx, key_len)

        if key == rest do
          value = String.slice(str, value_idx, str_len - value_idx)
          {:halt, Map.put(map, key, value)}
        else
          value = String.slice(str, value_idx, value_len)
          {:cont, Map.put(map, key, value)}
        end
      end
    )
  end
end
