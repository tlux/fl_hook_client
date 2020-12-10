defmodule FLHook.CommandSerializer do
  @moduledoc false

  alias FLHook.Command
  alias FLHook.Utils

  @char_map %{
    "\r" => "\\r",
    "\n" => "\\n"
  }

  @spec to_string(FLHook.command()) ::
          String.t()
  def to_string({cmd, args}) when is_binary(cmd) and is_list(args) do
    [cmd | args]
    |> Enum.join(" ")
    |> escape_newlines()
  end

  def to_string(cmd) when is_binary(cmd) do
    escape_newlines(cmd)
  end

  def to_string(command) do
    command
    |> Command.to_cmd()
    |> __MODULE__.to_string()
  end

  defp escape_newlines(str) do
    Utils.map_chars(str, @char_map)
  end
end
