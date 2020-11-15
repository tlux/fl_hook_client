defmodule FLHook.Client.Reply do
  @moduledoc false

  defstruct [:client, chardata: [], lines: [], status: :pending]

  @line_sep "\r\n"

  @type t :: %__MODULE__{
          client: GenServer.from(),
          chardata: IO.chardata(),
          lines: [String.t()],
          status: :pending | :ok | {:error, binary}
        }

  @spec lines(t) :: [binary]
  def lines(%__MODULE__{} = reply) do
    Enum.reverse(reply.lines)
  end

  @spec add_chunk(t, binary) :: t
  def add_chunk(%__MODULE__{status: :pending} = reply, chunk) do
    data = [reply.chardata, chunk]

    {status, lines} =
      data
      |> IO.chardata_to_string()
      |> String.splitter(@line_sep)
      |> Enum.reduce_while({:pending, []}, fn
        "OK" <> _, {_, lines} ->
          {:cont, {:ok, lines}}

        "ERR " <> reason, {_, lines} ->
          {:cont, {{:error, String.trim_trailing(reason)}, lines}}

        line, {:pending, lines} ->
          {:cont, {:pending, [line | lines]}}

        _line, acc ->
          {:halt, acc}
      end)

    %{reply | chardata: data, lines: lines, status: status}
  end
end
