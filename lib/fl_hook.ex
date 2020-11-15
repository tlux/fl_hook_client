defmodule FLHook do
  @moduledoc """
  Documentation for `FLHook`.
  """

  alias FLHook.Client

  def help(pid) do
    pid
    |> Client.cmd!("help")
    |> to_string()
    |> IO.puts()
  end

  def readcharfile(pid, name) do
    with {:ok, result} <- Client.cmd(pid, "readcharfile #{name}") do
      {:ok,
       result.lines
       |> Stream.map(fn "l " <> line -> line end)
       |> Enum.join("\r\n")}
    end
  end
end
