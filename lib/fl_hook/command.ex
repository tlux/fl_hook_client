defmodule FLHook.Command do
  alias FLHook.Dispatchable
  alias FLHook.Utils

  @char_map %{
    "\r" => "\\r",
    "\n" => "\\n"
  }

  @type command ::
          String.t() | {String.t(), [String.Chars.t()]} | Dispatchable.t()

  @doc false
  @spec to_string(command) ::
          String.t()
  def to_string({cmd, args}) when is_binary(cmd) and is_list(args) do
    [cmd | args]
    |> Enum.join(" ")
    |> escape_newlines()
  end

  def to_string(cmd) when is_binary(cmd) do
    escape_newlines(cmd)
  end

  def to_string(dispatchable) do
    dispatchable
    |> Dispatchable.to_cmd()
    |> __MODULE__.to_string()
  end

  defp escape_newlines(str) do
    Utils.map_chars(str, @char_map)
  end
end
