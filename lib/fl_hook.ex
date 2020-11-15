defmodule FLHook do
  @moduledoc """
  Documentation for `FLHook`.
  """

  def readcharfile(pid, name) do
    with {:ok, charfile} <- FLHook.Client.cmd(pid, "readcharfile #{name}") do
      {:ok,
       charfile
       |> Stream.map(fn "l " <> line -> line end)
       |> Enum.join("\r\n")}
    end
  end
end
