defmodule FLHook.Charfile do
  alias FLHook.Client
  alias FLHook.Result

  @enforce_keys [:client, :charname, :data]
  defstruct [:client, :charname, :data]

  @type t :: %__MODULE__{
          client: Client.client(),
          charname: String.t(),
          data: [binary]
        }

  def read(client, charname, timeout \\ :infinity) do
    with {:ok, %Result{lines: lines}} <-
           Client.cmd(client, {"readcharfile", [charname]}, timeout) do
      {:ok,
       %__MODULE__{
         client: client,
         charname: charname,
         data:
           Enum.map(lines, fn
             "l " <> l -> l
             _ -> raise ArgumentError, "charfile has unexpected format"
           end)
       }}
    end
  end

  def save(charfile) do
    Client.cmd(
      charfile.client,
      {"writecharfile", [charfile.charname, charfile.data]}
    )
  end

  @spec fetch(t, String.t(), String.t()) :: {:ok, String.t()} | :error
  def fetch(charfile, section, key) do
    case get_values(charfile, section, key) do
      [value | _] -> {:ok, value}
      _ -> :error
    end
  end

  @spec get_values(t, String.t(), String.t()) :: [String.t()]
  def get_values(charfile, section, key) do
    charfile.data
    |> Stream.map(&parse_row/1)
    |> Enum.reduce(%{section: nil, values: []}, fn
      {:section, new_section}, acc ->
        %{acc | section: new_section}

      {:record, ^key, value}, %{section: ^section, values: values} ->
        %{section: section, values: [value | values]}

      _, acc ->
        acc
    end)
    |> Map.fetch!(:values)
    |> Enum.reverse()
  end

  def update(charfile, section, key, fun) do
    charfile.data
    |> Stream.map(fn line -> {line, parse_row(line)} end)
    |> Enum.reduce(%{section: nil, lines: []}, fn
      {line, {:section, new_section}}, %{lines: lines} ->
        %{section: new_section, lines: [line | lines]}

      {_, {:record, ^key, value}}, %{section: ^section, lines: lines} ->
        %{
          section: section,
          lines: ["#{key} = #{Enum.join(fun.(value), ", ")}" | lines]
        }

      {line, _}, %{lines: lines} = acc ->
        %{acc | lines: [line | lines]}
    end)
    |> then(fn %{lines: lines} ->
      %{charfile | data: Enum.reverse(lines)}
    end)
  end

  @section_regex ~r/\A\[(?<section>.+)\]/

  defp parse_row(""), do: {:raw, ""}

  defp parse_row(row) do
    case Regex.named_captures(@section_regex, row) do
      %{"section" => section} ->
        {:section, section}

      _ ->
        case String.split(row, "=", trim: true, parts: 2) do
          [key, value] ->
            {:record, String.trim(key),
             value
             |> String.split(",", trim: true)
             |> Enum.map(&String.trim/1)}

          _ ->
            {:raw, row}
        end
    end
  end
end
