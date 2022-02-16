defmodule FLHook.Result do
  @moduledoc """
  A struct that contains result data and provides helpers to decode the
  contained data.
  """

  alias FLHook.Params
  alias FLHook.Utils

  defstruct lines: []

  @type t :: %__MODULE__{lines: [String.t()]}

  @doc """
  Converts the result to a string.
  """
  @spec to_string(t) :: String.t()
  def to_string(%__MODULE__{} = result) do
    Enum.join(result.lines, Utils.line_sep())
  end

  @doc """
  Converts a multiline result to a params list.
  """
  @spec params_list(t) :: [Params.t()]
  def params_list(%__MODULE__{} = result) do
    Enum.map(result.lines, &Params.parse/1)
  end

  @doc """
  Converts a result to params. When the result has multiple lines only the first
  one is being processed.
  """
  @spec params(t) :: Params.t()
  def params(%__MODULE__{} = result) do
    case result.lines do
      [line | _] -> Params.parse(line)
      _ -> Params.new()
    end
  end

  @doc """
  Fetches the param with the specified key from the params collection.
  Optionally allows specification of a type to coerce the param to.
  """
  @spec param(t, Params.key(), Params.param_type()) :: {:ok, any} | :error
  def param(%__MODULE__{} = result, key, type \\ :string) do
    result
    |> params()
    |> Params.fetch(key, type)
  end

  @doc """
  Fetches the param with the specified key from the params collection.
  Optionally allows specification of a type to coerce the param to. Raises when
  the param is missing or could not be coerced to the given type.
  """
  @spec param!(t, Params.key(), Params.param_type()) :: any | no_return
  def param!(%__MODULE__{} = result, key, type \\ :string) do
    result
    |> params()
    |> Params.fetch!(key, type)
  end

  @doc """
  Converts the result to a file stream. May raise when the result is no file.
  """
  @spec file_stream!(t) :: Enum.t() | no_return
  def file_stream!(%__MODULE__{} = result) do
    Stream.map(result.lines, fn
      "l " <> line -> line
      _ -> raise ArgumentError, "result is not a file"
    end)
  end

  @doc """
  Converts the result to a file string. May raise when the result is no file.
  """
  @spec file!(t) :: String.t() | no_return
  def file!(%__MODULE__{} = result) do
    result
    |> file_stream!()
    |> Enum.join(Utils.line_sep())
  end

  defimpl String.Chars do
    defdelegate to_string(result), to: FLHook.Result
  end
end
