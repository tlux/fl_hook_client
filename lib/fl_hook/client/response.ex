defmodule FLHook.Client.Response do
  @moduledoc false

  alias FLHook.Client.Request
  alias FLHook.Utils

  @enforce_keys [:request_id]
  defstruct [:request_id, :client, chardata: [], rows: [], status: :pending]

  @type t :: %__MODULE__{
          chardata: IO.chardata(),
          client: nil | GenServer.from(),
          request_id: Request.id(),
          rows: [binary],
          status: :pending | :ok | {:error, String.t()}
        }

  @spec add_chunk(t, binary) :: t
  def add_chunk(%__MODULE__{status: :pending} = response, chunk) do
    chardata = [response.chardata, chunk]

    chardata
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
      %{response | chardata: chardata, status: status, rows: rows}
    end)
  end

  @spec rows(t) :: [binary]
  def rows(%__MODULE__{status: :ok, rows: rows}) do
    Enum.reverse(rows)
  end
end
