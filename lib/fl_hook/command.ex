defmodule FLHook.Command do
  @moduledoc """
  The command module.
  """

  alias FLHook.Utils

  @char_map %{
    "\r" => "\\r",
    "\n" => "\\n"
  }

  @typedoc """
  Type representing an FLHook command string
  """
  @type command :: String.t()

  @doc false
  @spec dump(command) :: String.t()
  def dump(cmd) when is_binary(cmd) do
    cmd
    |> Utils.map_chars(@char_map)
    |> then(&(&1 <> Utils.line_sep()))
  end
end
