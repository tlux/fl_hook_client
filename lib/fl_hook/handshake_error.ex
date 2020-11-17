defmodule FLHook.HandshakeError do
  defexception [:actual_message]

  @impl true
  def message(_error) do
    "Socket is not a valid FLHook socket"
  end
end
