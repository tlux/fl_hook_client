defmodule FLHook do
  @moduledoc """
  Documentation for `FLHook`.
  """

  alias FLHook.Client
  alias FLHook.Utils

  def help(client) do
    client
    |> Client.cmd!("help")
    |> to_string()
    |> IO.puts()
  end

  def readcharfile(client, name) do
    with {:ok, result} <- Client.cmd(client, "readcharfile #{name}") do
      {:ok,
       result.lines
       |> Stream.map(fn "l " <> line -> line end)
       |> Enum.join(Utils.line_sep())}
    end
  end
end
