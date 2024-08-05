defmodule FLHook.Client.Reply do
  @moduledoc false

  alias FLHook.Utils

  defstruct [:client, chardata: [], rows: [], status: :pending]

  @type t :: %__MODULE__{
          chardata: IO.chardata(),
          client: nil | GenServer.from(),
          rows: [binary],
          status: :pending | :ok | {:error, String.t()}
        }

  @spec add_chunk(t, binary) :: t
  def add_chunk(%__MODULE__{status: :pending} = reply, chunk) do
    data = [reply.chardata, chunk]

    data
    |> IO.chardata_to_string()
    |> String.splitter(Utils.line_sep())
    |> Enum.reduce_while({:pending, []}, fn
      "OK" <> _, {_, rows} ->
        {:cont, {:ok, rows}}

      "ERR " <> reason, {_, rows} ->
        {:cont, {{:error, String.trim_trailing(reason)}, rows}}

      row, {:pending, rows} ->
        {:cont, {:pending, [row | rows]}}

      _row, acc ->
        {:halt, acc}
    end)
    |> then(fn {status, rows} ->
      %{reply | chardata: data, status: status, rows: rows}
    end)
  end

  @spec rows(t) :: [binary]
  def rows(%__MODULE__{status: :ok, rows: rows}) do
    Enum.reverse(rows)
  end
end
