defmodule FLHook.SocketError do
  defexception [:reason]

  @type t :: %__MODULE__{reason: :closed | :inet.posix()}

  @impl true
  def message(%{reason: :closed}) do
    "Socket error: connection closed"
  end

  def message(error) do
    "Socket error: #{:inet.format_error(error.reason)}"
  end
end
