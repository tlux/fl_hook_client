defmodule FLHook.RowsCountError do
  @moduledoc """
  An error indicating a command returned too many or too few rows.
  """

  @enforce_keys [:actual, :expected]
  defexception [:actual, :expected]

  def message(error) do
    "Expected #{rows(error.expected)} but got #{error.actual}"
  end

  defp rows(1), do: "1 row"
  defp rows(n), do: "#{n} rows"
end
