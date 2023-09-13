defmodule FLHook.Result do
  @moduledoc """
  A struct that contains result data and provides helpers to decode the
  contained data.
  """

  alias FLHook.Dict
  alias FLHook.Utils

  defstruct lines: []

  @type t :: %__MODULE__{lines: [String.t()]}

  @doc """
  Converts a multiline result to a list of dictionaries.
  """
  @spec all(t) :: [Dict.t()]
  def all(%__MODULE__{} = result) do
    Enum.map(result.lines, &Dict.parse/1)
  end

  @doc """
  Converts a result to dictionary. When the result has multiple lines only the
  first one is being returned. When first line is no valid dictionary, an empty
  dictionary is returned.
  """
  @spec one(t) :: Dict.t()
  def one(%__MODULE__{} = result) do
    case result.lines do
      [line | _] -> Dict.parse(line)
      _ -> Dict.new()
    end
  end

  @doc """
  Converts the result to a file stream. Raises when the result is no file.
  """
  @spec file_stream!(t) :: Enum.t() | no_return
  def file_stream!(%__MODULE__{} = result) do
    Stream.map(result.lines, fn
      "l " <> line -> line
      _ -> raise ArgumentError, "result is not a file"
    end)
  end

  @doc """
  Converts the result to a file string. Raises when the result is no file.
  """
  @spec file!(t) :: String.t() | no_return
  def file!(%__MODULE__{} = result) do
    result
    |> file_stream!()
    |> Enum.join(Utils.line_sep())
  end

  @doc """
  Gets the raw result string.
  """
  @doc since: "2.1.0"
  @spec raw(t) :: binary
  def raw(%__MODULE__{} = result) do
    Enum.join(result.lines, Utils.line_sep())
  end

  @doc """
  Converts the result to a string.
  """
  @spec to_string(t) :: String.t()
  def to_string(%__MODULE__{} = result), do: raw(result)

  defimpl String.Chars do
    defdelegate to_string(result), to: FLHook.Result
  end
end
