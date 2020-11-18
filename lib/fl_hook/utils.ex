defmodule FLHook.Utils do
  @moduledoc false

  @line_sep "\r\n"

  @spec line_sep() :: String.t()
  def line_sep, do: @line_sep

  @spec map_chars(String.t(), %{optional(String.t()) => String.t()}) :: String.t()
  def map_chars(str, map) do
    Enum.reduce(map, str, fn {char, mapped_char}, str ->
      String.replace(str, char, mapped_char)
    end)
  end
end
