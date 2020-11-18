defmodule FLHook.Command do
  alias FLHook.Utils

  @char_map %{
    "\r" => "\\r",
    "\n" => "\\n"
  }

  @spec to_string(String.Chars.t() | {String.t(), [String.Chars.t()]}) :: String.t()
  def to_string({cmd, []}) when is_binary(cmd), do: cmd

  def to_string({cmd, args}) when is_binary(cmd) and is_list(args) do
    args_str = args |> Enum.map(&__MODULE__.to_string/1) |> Enum.join(" ")
    "#{cmd} #{args_str}"
  end

  def to_string(cmd) do
    cmd
    |> Kernel.to_string()
    |> Utils.map_chars(cmd, @char_map)
  end
end
